import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris


PlasmoidItem {
    id: widget

    Plasmoid.status: (showWhenNoMedia || player.ready || splayerOnline) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    Plasmoid.backgroundHints: plasmoid.configuration.desktopWidgetBg

    readonly property int formFactor: Plasmoid.formFactor
    readonly property int location: Plasmoid.location
    readonly property bool showWhenNoMedia: plasmoid.configuration.showWhenNoMedia
    readonly property bool hidePlayerControlBinds: plasmoid.configuration.hidePlayerControlBindsInHoverTooltip

    readonly property font baseFont: plasmoid.configuration.useCustomFont ? plasmoid.configuration.customFont : Kirigami.Theme.defaultFont

    // =========================================================================
    // SPlayer WebSocket properties
    // =========================================================================
    property bool wsEnabled: plasmoid.configuration.wsEnabled
    property string wsUrl: plasmoid.configuration.wsUrl
    property int wsReconnectIntervalMs: plasmoid.configuration.wsReconnectIntervalMs
    property string wsDisplayMode: plasmoid.configuration.wsDisplayMode
    property string textAlign: plasmoid.configuration.textAlign ? plasmoid.configuration.textAlign : "center"
    property int fixedWidth: plasmoid.configuration.fixedWidth
    property int fixedHeight: plasmoid.configuration.fixedHeight
    property int customFontSize: plasmoid.configuration.fontSize
    property string customFontFamily: plasmoid.configuration.fontFamily
    property string coverAlign: plasmoid.configuration.coverAlign
    property int coverSize: plasmoid.configuration.coverSize
    property int coverRadius: plasmoid.configuration.coverRadius
    property bool showCover: plasmoid.configuration.showCover
    property string currentCoverUrl: ""
    readonly property string preferredCoverUrl: player.artUrl || currentCoverUrl
    property int coverRefreshNonce: 0
    property string lastCoverRequestKey: ""
    property bool showBackground: plasmoid.configuration.showBackground
    property bool useCustomColors: plasmoid.configuration.useCustomColors
    property color customPlayedColor: plasmoid.configuration.customPlayedColor
    property color customUnplayedColor: plasmoid.configuration.customUnplayedColor
    property bool showTranslation: plasmoid.configuration.showTranslation
    property int customTranslationFontSize: plasmoid.configuration.translationFontSize
    property int lineSpacing: plasmoid.configuration.lineSpacing
    property string animationType: plasmoid.configuration.animationType
    property int autoHideDelay: plasmoid.configuration.autoHideDelay
    property bool autoHidden: false
    property color playedColor: useCustomColors ? customPlayedColor : Kirigami.Theme.highlightColor
    property color unplayedColor: useCustomColors ? customUnplayedColor : Kirigami.Theme.textColor
    property color outlineColor: "black"
    property string fontFamily: customFontFamily !== "" ? customFontFamily : Kirigami.Theme.defaultFont.family
    property int fontSize: customFontSize > 0 ? customFontSize : (Kirigami.Theme.defaultFont.pixelSize + 2)
    property real lineHeightScale: 1.5
    property int translationFontSize: customTranslationFontSize > 0 ? customTranslationFontSize : Math.max(10, fontSize - 2)
    property var wsClient: null
    property bool wsSupported: true
    property bool splayerOnline: false
    property string currentSong: ""
    property string currentArtist: ""
    property var lyrics: []
    property int currentLineIndex: -1
    property string translatedText: (currentLineIndex >= 0 && lyrics[currentLineIndex] && lyrics[currentLineIndex].trans) ? lyrics[currentLineIndex].trans : ""
    property bool hasLyrics: lyrics && lyrics.length > 0
    property string pendingNoLyricSongKey: ""
    property real pendingNoLyricTimestamp: 0
    property real smoothTime: 0
    property bool isPlaying: false
    property string wordKey: ""
    property var wordList: []
    property var prevWordList: []
    property real wordInScale: 1
    property real wordOutScale: 1
    property real wordInScaleY: 1
    property real wordOutScaleY: 1
    property real wordInOpacity: 1
    property real wordOutOpacity: 0
    property real lastFrameTimestamp: 0
    property real lastLyricUpdateTimestamp: 0
    property string singleLineText: ""

    // =========================================================================
    // SPlayer WebSocket functions
    // =========================================================================
    function ensureWsClient() {
        if (wsClient)
            return;
        wsSupported = true;
        var candidates = ['import QtWebSockets 1.0; WebSocket { }', 'import QtWebSockets; WebSocket { }'];
        var created = null;
        for (var i = 0; i < candidates.length; i++) {
            try {
                created = Qt.createQmlObject(candidates[i], widget, "wsClient");
                break;
            } catch (e) {
                created = null;
            }
        }
        if (!created) {
            wsSupported = false;
            return;
        }
        wsClient = created;
        wsClient.active = false;
        try {
            wsClient.textMessageReceived.connect(widget.onWsTextMessage);
        } catch (e) {
        }
        try {
            wsClient.statusChanged.connect(function() {
                widget.onWsStatusChanged(wsClient.status);
            });
        } catch (e) {
        }
        try {
            if (typeof wsClient.errorOccurred !== "undefined") {
                wsClient.errorOccurred.connect(widget.onWsDisconnected);
            } else if (typeof wsClient.error !== "undefined") {
                wsClient.error.connect(widget.onWsDisconnected);
            }
        } catch (e) {
        }
        wsClient.url = wsUrl;
        tryReconnectWs();
    }

    function tryReconnectWs() {
        if (!wsSupported)
            return;
        ensureWsClient();
        if (!wsClient)
            return;
        if (!wsEnabled) {
            wsReconnectTimer.running = false;
            wsClient.active = false;
            return;
        }
        if (wsClient.url !== wsUrl) {
            wsClient.active = false;
            wsClient.url = wsUrl;
        }
        if (wsClient.status === 1) {
            wsReconnectTimer.running = false;
            return;
        }
        wsClient.active = true;
        wsReconnectTimer.running = true;
    }

    function onWsStatusChanged(status) {
        if (!wsClient)
            return;
        if (status === 1) {
            splayerOnline = true;
            wsReconnectTimer.running = false;
            sendWsJson({ "type": "get-song-info" });
            Plasmoid.status = PlasmaCore.Types.ActiveStatus;
        } else if (status === 3) {
            onWsDisconnected();
        }
    }

    function onWsDisconnected() {
        if (!wsEnabled)
            return;
        wsReconnectTimer.running = true;
        isPlaying = false;
        splayerOnline = false;
        currentCoverUrl = "";
        clearLyrics();
        if (!player.ready && !showWhenNoMedia) {
            Plasmoid.status = PlasmaCore.Types.HiddenStatus;
        }
    }

    function sendWsJson(obj) {
        if (!wsClient)
            return;
        try {
            wsClient.sendTextMessage(JSON.stringify(obj));
        } catch (e) {
        }
    }

    // Prefer the configured SPlayer WebSocket while it is online, then use MPRIS.
    readonly property bool splayerControlsAvailable: wsEnabled && splayerOnline && wsClient !== null

    function sendSPlayerControl(command) {
        if (!splayerControlsAvailable)
            return false;
        sendWsJson({
            "type": "control",
            "data": { "command": command }
        });
        splayerControlRefreshTimer.restart();
        return true;
    }

    function togglePlayback() {
        if (!sendSPlayerControl("toggle"))
            player.playPause();
    }

    function previousTrack() {
        if (!sendSPlayerControl("prev"))
            player.previous();
    }

    function nextTrack() {
        if (!sendSPlayerControl("next"))
            player.next();
    }

    function normalizeCoverUrl(raw, forceRefresh) {
        var cleaned = String(raw || "").replace(/[`\s]/g, "");
        if (cleaned === "")
            return "";
        if (cleaned.indexOf("data:") === 0)
            return cleaned;
        if (forceRefresh || coverRefreshNonce > 0) {
            if (cleaned.indexOf("?") >= 0)
                return cleaned + "&t=" + coverRefreshNonce;
            return cleaned + "?t=" + coverRefreshNonce;
        }
        return cleaned;
    }

    function clearLyrics() {
        lyrics = [];
        currentLineIndex = -1;
        widget.wordKey = "";
        widget.wordList = [];
        widget.prevWordList = [];
        widget.wordInScale = 1;
        widget.wordOutScale = 1;
        widget.wordInOpacity = 1;
        widget.wordOutOpacity = 0;
    }

    function extractCoverUrl(data, isSongChanged) {
        if (!data)
            return "";
        if (data.coverSize) {
            if (typeof data.coverSize === "string")
                return normalizeCoverUrl(data.coverSize, isSongChanged);
            var c = data.coverSize.s || data.coverSize.m || data.coverSize.l || data.coverSize.xl || data.coverSize.url || "";
            if (c)
                return normalizeCoverUrl(c, isSongChanged);
        }
        var candidates = [data.cover, data.coverUrl, data.pic, data.picUrl, data.albumPic, data.albumPicUrl, data.image, data.img, data.thumbnail, data.coverSmall, data.coverMedium, data.coverLarge, data.coverXL];
        for (var i = 0; i < candidates.length; i++) {
            if (candidates[i])
                return normalizeCoverUrl(candidates[i], isSongChanged);
        }
        return "";
    }

    function onWsTextMessage(message) {
        var rootObj = null;
        try {
            rootObj = JSON.parse(message);
        } catch (e) {
            return;
        }
        if (!rootObj || !rootObj.type)
            return;
        splayerOnline = true;
        var type = rootObj.type;
        var data = rootObj.data || {};
        if (type === "welcome")
            return;
        if (type === "song-change" || type === "song-info") {
            var newSong = data.playName || data.name || "";
            var newArtist = data.artistName || data.artist || "";
            var isSongChanged = (newSong !== currentSong || newArtist !== currentArtist);
            currentSong = newSong;
            currentArtist = newArtist;
            if (isSongChanged)
                coverRefreshNonce = Date.now();
            if (data.playStatus !== undefined)
                isPlaying = (String(data.playStatus) === "true" || String(data.playStatus) === "play" || String(data.playStatus) === "playing");
            else if (data.status !== undefined)
                isPlaying = (String(data.status) === "true" || String(data.status) === "play" || String(data.status) === "playing");
            if (data.currentTime !== undefined)
                syncTime(Number(data.currentTime) || 0);
            var coverUrl = extractCoverUrl(data, isSongChanged);
            if (coverUrl !== "") {
                if (isSongChanged) {
                    currentCoverUrl = "";
                    Qt.callLater(function() {
                        currentCoverUrl = coverUrl;
                    });
                } else {
                    currentCoverUrl = coverUrl;
                }
            } else if (isSongChanged && (data.cover === "" || data.cover === null)) {
                currentCoverUrl = "";
            } else if (type === "song-change" && isSongChanged) {
                var songKey = currentSong + "||" + currentArtist;
                if (lastCoverRequestKey !== songKey) {
                    lastCoverRequestKey = songKey;
                    sendWsJson({ "type": "get-song-info" });
                }
            }
            var hasLyricPayload = (data.yrcData && data.yrcData.length) || (data.lrcData && data.lrcData.length);
            var hasLyricField = (data.yrcData !== undefined) || (data.lrcData !== undefined);
            if (hasLyricPayload) {
                noLyricClearTimer.stop();
                handleLyricPayload(data);
            } else if (hasLyricField) {
                noLyricClearTimer.stop();
                clearLyrics();
            } else if (isSongChanged) {
                pendingNoLyricSongKey = currentSong + "||" + currentArtist;
                pendingNoLyricTimestamp = Date.now();
                noLyricClearTimer.restart();
            }
            checkCurrentLine();
            updateDisplayText();
            updateAutoHideState();
            return;
        }
        if (type === "status-change") {
            if (data.playStatus !== undefined)
                isPlaying = (String(data.playStatus) === "true" || String(data.playStatus) === "play" || String(data.playStatus) === "playing");
            else if (data.status !== undefined)
                isPlaying = (String(data.status) === "true" || String(data.status) === "play" || String(data.status) === "playing");
            updateAutoHideState();
            return;
        }
        if (type === "control-response") {
            splayerControlRefreshTimer.restart();
            return;
        }
        if (type === "progress-change") {
            if (data.currentTime !== undefined) {
                syncTime(Number(data.currentTime) || 0);
                updateDisplayText();
                resetAutoHideActivity();
            }
            return;
        }
        if (type === "lyric-change") {
            noLyricClearTimer.stop();
            handleLyricPayload(data);
            checkCurrentLine();
            updateDisplayText();
            return;
        }
    }

    function syncTime(serverTimeMs) {
        var newTime = serverTimeMs / 1000;
        var diff = newTime - smoothTime;
        if (Math.abs(diff) > 0.5) {
            smoothTime = newTime;
            return;
        }
        if (newTime > smoothTime)
            smoothTime = newTime;
    }

    function handleLyricPayload(data) {
        lastLyricUpdateTimestamp = Date.now();
        var arr = [];
        if (data.yrcData && data.yrcData.length) {
            arr = data.yrcData;
        } else if (data.lrcData && data.lrcData.length) {
            arr = data.lrcData;
        } else {
            clearLyrics();
            return;
        }
        var parsed = [];
        for (var i = 0; i < arr.length; i++) {
            var line = arr[i];
            if (!line)
                continue;
            var timeMs = Number(line.startTime || 0);
            var endSec = 0;
            var text = "";
            var trans = "";
            var words = [];
            if (line.text !== undefined)
                text = String(line.text);
            else if (line.lyric !== undefined)
                text = String(line.lyric);
            if (line.words && line.words.length) {
                for (var w = 0; w < line.words.length; w++) {
                    if (!line.words[w])
                        continue;
                    var wordText = "";
                    if (line.words[w].word !== undefined)
                        wordText = String(line.words[w].word);
                    var startTime = 0;
                    var endTime = 0;
                    if (line.words[w].startTime !== undefined)
                        startTime = Number(line.words[w].startTime) / 1000;
                    if (line.words[w].endTime !== undefined)
                        endTime = Number(line.words[w].endTime) / 1000;
                    words.push({ "word": wordText, "startTime": startTime, "endTime": endTime });
                    if (endTime > endSec)
                        endSec = endTime;
                }
            } else {
                var nextTime = 0;
                if (i + 1 < arr.length && arr[i + 1].startTime)
                    nextTime = Number(arr[i + 1].startTime) / 1000;
                else
                    nextTime = (timeMs / 1000) + 5;
                words.push({ "word": text, "startTime": timeMs / 1000, "endTime": nextTime });
                endSec = nextTime;
            }
            if (line.translatedLyric)
                trans = String(line.translatedLyric);
            parsed.push({ "time": timeMs / 1000, "end": endSec, "text": text, "trans": trans, "words": words });
        }
        for (var j = 0; j < parsed.length; j++) {
            if (parsed[j].end <= parsed[j].time) {
                if (j + 1 < parsed.length)
                    parsed[j].end = parsed[j + 1].time;
                else
                    parsed[j].end = parsed[j].time + 5;
            }
        }
        lyrics = parsed;
        currentLineIndex = -1;
    }

    function checkCurrentLine() {
        if (!lyrics || !lyrics.length) {
            currentLineIndex = -1;
            return;
        }
        var t = smoothTime;
        var idx = -1;
        if (t < lyrics[0].time) {
            idx = 0;
        } else {
            for (var i = 0; i < lyrics.length; i++) {
                if (lyrics[i].time <= t)
                    idx = i;
                else
                    break;
            }
        }
        if (currentLineIndex !== idx) {
            currentLineIndex = idx;
            syncWordData();
        }
    }

    function updateDisplayText() {
        if (!wsEnabled)
            return;
        if (!wsSupported) {
            singleLineText = "WebSocket not available";
            return;
        }
        if (wsDisplayMode === "song") {
            if (currentSong && currentArtist)
                singleLineText = currentSong + " - " + currentArtist;
            else if (currentSong)
                singleLineText = currentSong;
            else
                singleLineText = "";
            return;
        }
        if (wsDisplayMode === "artist") {
            singleLineText = currentArtist || "";
            return;
        }
        singleLineText = "";
    }

    function wordKeyFor(words) {
        if (!words || words.length <= 0)
            return "";
        var first = words[0];
        var last = words[words.length - 1];
        var key = "" + words.length + ":" + first.startTime + "-" + last.endTime + ":";
        var limit = Math.min(words.length, 12);
        for (var i = 0; i < limit; i++) {
            key += words[i].word;
        }
        return key;
    }

    function syncWordData() {
        var words = [];
        if (currentLineIndex >= 0 && lyrics[currentLineIndex] && lyrics[currentLineIndex].words)
            words = lyrics[currentLineIndex].words;
        if (!words || words.length <= 0) {
            widget.wordKey = "";
            widget.wordList = [];
            widget.prevWordList = [];
            widget.wordInScale = 1;
            widget.wordOutScale = 1;
            widget.wordInOpacity = 1;
            widget.wordOutOpacity = 0;
            return;
        }
        var nextKey = wordKeyFor(words);
        if (nextKey === widget.wordKey) {
            widget.wordList = words;
            return;
        }
        widget.prevWordList = widget.wordList;
        widget.wordList = words;
        widget.wordKey = nextKey;
        wordTransAnim.restart();
    }

    function updateAutoHideState() {
        if (widget.autoHideDelay <= 0) {
            autoHideTimer.stop();
            widget.autoHidden = false;
            return;
        }
        if (widget.isPlaying) {
            autoHideTimer.stop();
            widget.autoHidden = false;
        } else {
            if (!autoHideTimer.running) {
                autoHideTimer.restart();
            }
        }
    }

    function resetAutoHideActivity() {
        if (widget.autoHideDelay <= 0)
            return;
        if (widget.autoHidden)
            widget.autoHidden = false;
        autoHideTimer.restart();
    }

    // =========================================================================
    // SPlayer Timers
    // =========================================================================
    Timer {
        id: wsReconnectTimer
        interval: Math.max(500, widget.wsReconnectIntervalMs)
        repeat: true
        running: false
        onTriggered: widget.tryReconnectWs()
    }

    Timer {
        id: splayerControlRefreshTimer
        interval: 450
        repeat: false
        onTriggered: widget.sendWsJson({ "type": "get-song-info" })
    }

    Timer {
        id: smoothTimer
        interval: 16
        repeat: true
        running: widget.isPlaying && widget.wsEnabled
        onRunningChanged: {
            if (running)
                widget.lastFrameTimestamp = Date.now();
        }
        onTriggered: {
            var now = Date.now();
            var dt = (now - widget.lastFrameTimestamp) / 1000;
            widget.lastFrameTimestamp = now;
            if (dt > 0.1)
                dt = 0.016;
            widget.smoothTime += dt;
            widget.checkCurrentLine();
        }
    }

    Timer {
        id: noLyricClearTimer
        interval: 1200
        repeat: false
        onTriggered: {
            var key = currentSong + "||" + currentArtist;
            if (pendingNoLyricSongKey === key && Date.now() - lastLyricUpdateTimestamp > 1000)
                clearLyrics();
        }
    }

    Timer {
        id: autoHideTimer
        interval: Math.max(1000, widget.autoHideDelay * 1000)
        repeat: false
        running: false
        onTriggered: {
            widget.autoHidden = true;
        }
    }

    // =========================================================================
    // SPlayer word transition animation
    // =========================================================================
    ParallelAnimation {
        id: wordTransAnim
        running: false
        SequentialAnimation {
            ScriptAction {
                script: {
                    widget.wordOutScale = 1;
                    widget.wordOutScaleY = 1;
                    widget.wordOutOpacity = (widget.prevWordList && widget.prevWordList.length > 0) ? 1 : 0;
                    if (widget.animationType === "scale") {
                        widget.wordInScale = 0.85;
                        widget.wordInScaleY = 1;
                    } else if (widget.animationType === "flip") {
                        widget.wordInScale = 1;
                        widget.wordInScaleY = 0;
                    } else {
                        widget.wordInScale = 1;
                        widget.wordInScaleY = 1;
                    }
                    widget.wordInOpacity = 0;
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: widget; property: "wordOutScale"
                    to: widget.animationType === "scale" ? 0.85 : 1
                    duration: widget.animationType === "none" ? 0 : 140
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: widget; property: "wordOutScaleY"
                    to: widget.animationType === "flip" ? 0 : 1
                    duration: widget.animationType === "none" ? 0 : 140
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: widget; property: "wordOutOpacity"
                    to: 0
                    duration: widget.animationType === "none" ? 0 : 140
                    easing.type: Easing.InCubic
                }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: widget.animationType === "none" ? 0 : 60 }
            ParallelAnimation {
                NumberAnimation {
                    target: widget; property: "wordInScale"
                    to: 1
                    duration: widget.animationType === "none" ? 0 : 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: widget; property: "wordInScaleY"
                    to: 1
                    duration: widget.animationType === "none" ? 0 : 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: widget; property: "wordInOpacity"
                    to: 1
                    duration: widget.animationType === "none" ? 0 : 180
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // =========================================================================
    // Reactive handlers
    // =========================================================================
    onWsEnabledChanged: {
        if (!wsEnabled)
            splayerOnline = false;
        tryReconnectWs();
    }
    onWsUrlChanged: tryReconnectWs()
    onWsReconnectIntervalMsChanged: tryReconnectWs()
    onWsDisplayModeChanged: updateDisplayText()
    Component.onCompleted: ensureWsClient()
    onAutoHideDelayChanged: updateAutoHideState()
    onIsPlayingChanged: updateAutoHideState()
    onCurrentSongChanged: updateDisplayText()
    onCurrentArtistChanged: updateDisplayText()
    onSplayerOnlineChanged: {
        Plasmoid.status = (showWhenNoMedia || player.ready || splayerOnline) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    }
    onShowWhenNoMediaChanged: {
        Plasmoid.status = (showWhenNoMedia || player.ready || splayerOnline) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    }

    // =========================================================================
    // MPRIS Player
    // =========================================================================
    toolTipTextFormat: Text.PlainText
    toolTipMainText: {
        if (splayerOnline && currentSong) {
            return currentSong
        }
        return player.playbackStatus > Mpris.PlaybackStatus.Stopped ? player.title : i18n("No media playing")
    }
    toolTipSubText: {
        var text = ""
        if (splayerOnline && currentArtist) {
            text = i18nc("%1 is the media artist/author and %2 is the player name", "by %1 (SPlayer)", currentArtist)
        } else {
            text = player.artists ? i18nc("%1 is the media artist/author and %2 is the player name", "by %1 (%2)", player.artists, player.identity)
                : i18nc("%1 is the player name", "%1", player.identity)
        }
        if (!hidePlayerControlBinds) {
            text += "\n" + (player.playbackStatus === Mpris.PlaybackStatus.Playing ? i18n("Middle-click to pause") : i18n("Middle-click to play"))
            text += "\n" + i18n("Scroll to adjust volume")
            text += "\n" + (player.canRaise ? i18n("Ctrl+Click to bring player to the front") : i18n("This player can't be raised"))
        }
        return text
    }

    Player {
        id: player
        sourceIdentity: {
            if (!plasmoid.configuration.choosePlayerAutomatically) {
                return plasmoid.configuration.preferredPlayerIdentity
            }
        }
        onReadyChanged: {
            Plasmoid.status = (showWhenNoMedia || player.ready || splayerOnline) ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
        }
    }

    compactRepresentation: Compact {}
    fullRepresentation: Full {}
}
