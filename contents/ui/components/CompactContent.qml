import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool fillAvailableSpace: plasmoid.configuration.fillAvailableSpace

    property int paddingH: Kirigami.Units.smallSpacing
    property int paddingV: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))

    function staticX(containerWidth, contentWidth) {
        if (contentWidth <= containerWidth) {
            if (widget.textAlign === "right")
                return containerWidth - contentWidth;
            if (widget.textAlign === "center")
                return (containerWidth - contentWidth) / 2;
            return 0;
        }
        return 0;
    }

    visible: true
    opacity: widget.autoHidden ? 0 : 1
    implicitWidth: {
        if (widget.autoHidden) return 0;
        var w = widget.fixedWidth > 0 ? widget.fixedWidth : (Kirigami.Units.gridUnit * 10);
        if (widget.showCover && widget.preferredCoverUrl)
            w += widget.coverSize + paddingH;
        return w;
    }
    implicitHeight: {
        if (widget.fixedHeight > 0)
            return widget.fixedHeight;
        var h = Math.max(22, widget.fontSize * widget.lineHeightScale + paddingV * 2);
        if (widget.showTranslation && widget.translatedText !== "") {
            h += widget.translationFontSize + 4;
            h -= (widget.fontSize * 0.3);
        }
        if (widget.showCover && widget.preferredCoverUrl && widget.coverSize > h)
            return Math.max(h, widget.coverSize + paddingV * 2);
        return h;
    }
    Layout.minimumWidth: widget.fixedWidth > 0 ? widget.fixedWidth : (Kirigami.Units.gridUnit * 6)
    Layout.minimumHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillHeight: horizontal || fillAvailableSpace
    Layout.fillWidth: !horizontal || fillAvailableSpace

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.4)
        radius: Kirigami.Units.smallSpacing
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
        visible: widget.showBackground
    }

    Component {
        id: wordDelegate
        Item {
            property var wordData: modelData
            property string textStr: wordData.word !== undefined ? wordData.word : ""
            property double startTime: wordData.startTime !== undefined ? wordData.startTime : 0
            property double endTime: wordData.endTime !== undefined ? wordData.endTime : 0
            property int playState: {
                if (widget.smoothTime >= endTime) return 2;
                if (widget.smoothTime <= startTime) return 0;
                return 1;
            }
            width: baseText.implicitWidth
            height: widget.fontSize * widget.lineHeightScale

            Text {
                id: baseText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: textStr
                color: widget.unplayedColor
                font.pixelSize: widget.fontSize - 3
                font.family: widget.fontFamily
                font.weight: Font.DemiBold
                style: Text.Outline
                styleColor: widget.outlineColor
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: textStr
                color: widget.playedColor
                font: baseText.font
                style: Text.Outline
                styleColor: widget.outlineColor
                visible: playState === 2
            }

            Item {
                id: clipper
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true
                visible: playState === 1
                width: {
                    if (playState !== 1) return 0;
                    if (widget.wordList.length === 1) return parent.width;
                    var duration = endTime - startTime;
                    if (duration <= 0.001) return parent.width;
                    var progress = (widget.smoothTime - startTime) / duration;
                    return parent.width * progress;
                }
                Text {
                    text: textStr
                    color: widget.playedColor
                    font: baseText.font
                    style: Text.Outline
                    styleColor: widget.outlineColor
                    width: baseText.implicitWidth
                    height: parent.height
                    anchors.left: parent.left
                    anchors.top: parent.top
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: paddingH
        anchors.rightMargin: paddingH
        spacing: ((widget.coverAlign === "right" && widget.textAlign === "right") || (widget.coverAlign === "left" && widget.textAlign === "left")) ? (paddingH * 2) : paddingH
        layoutDirection: widget.coverAlign === "right" ? Qt.RightToLeft : Qt.LeftToRight

        Item {
            visible: widget.showCover && widget.preferredCoverUrl !== ""
            Layout.preferredWidth: widget.coverSize
            Layout.preferredHeight: widget.coverSize
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: widget.preferredCoverUrl
                fillMode: Image.PreserveAspectFit
                mipmap: true
                cache: false
                visible: widget.coverRadius <= 0
            }

            Image {
                id: roundedCover
                anchors.fill: parent
                source: widget.preferredCoverUrl
                fillMode: Image.PreserveAspectFit
                mipmap: true
                cache: false
                visible: widget.coverRadius > 0
                layer.enabled: widget.coverRadius > 0
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: roundedCover.width
                        height: roundedCover.height
                        radius: widget.coverRadius
                    }
                }
            }
        }

        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                id: contentCol
                anchors.centerIn: parent
                width: parent.width
                spacing: -widget.fontSize * 0.3 + widget.lineSpacing

                Item {
                    id: clipItem
                    width: parent.width
                    height: widget.fontSize * widget.lineHeightScale
                    clip: true

                    Item {
                        id: lyricLayer
                        width: parent.width
                        height: parent.height

                        Item {
                            anchors.fill: parent
                            visible: !widget.splayerOnline || !widget.hasLyrics
                            Row {
                                spacing: 0
                                x: root.staticX(clipItem.width, fallbackText.implicitWidth)
                                y: (lyricLayer.height - fallbackText.implicitHeight) / 2
                                Text {
                                    id: fallbackText
                                    text: widget.splayerOnline ? (widget.currentSong || "SPlayer Connected") : ""
                                    color: widget.unplayedColor
                                    font.pixelSize: widget.fontSize - 3
                                    font.bold: true
                                    font.family: widget.fontFamily
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Item {
                            id: wordOutLayer
                            anchors.fill: parent
                            opacity: widget.wordOutOpacity
                            scale: widget.wordOutScale
                            transformOrigin: Item.Center
                            visible: widget.wordOutOpacity > 0.001

                            Row {
                                id: wordOutRow
                                spacing: 0
                                x: root.staticX(clipItem.width, wordOutRow.implicitWidth)
                                y: (lyricLayer.height - wordOutRow.implicitHeight) / 2

                                Repeater {
                                    model: widget.prevWordList ? widget.prevWordList : []
                                    delegate: wordDelegate
                                }
                            }

                            transform: Scale {
                                yScale: widget.wordOutScaleY
                                origin.x: wordOutLayer.width / 2
                                origin.y: wordOutLayer.height / 2
                            }
                        }

                        Item {
                            id: wordInLayer
                            anchors.fill: parent
                            opacity: widget.wordInOpacity
                            scale: widget.wordInScale
                            transformOrigin: Item.Center

                            Row {
                                id: wordInRow
                                spacing: 0
                                x: {
                                    if (!widget.splayerOnline)
                                        return root.staticX(clipItem.width, wordInRow.implicitWidth);
                                    var maxOffset = Math.max(0, wordInRow.implicitWidth - clipItem.width);
                                    if (maxOffset <= 0)
                                        return root.staticX(clipItem.width, wordInRow.implicitWidth);
                                    if (!widget.wordList || widget.wordList.length <= 0)
                                        return 0;
                                    var start = widget.wordList[0].startTime;
                                    var end = widget.wordList[widget.wordList.length - 1].endTime;
                                    var lineDuration = end - start;
                                    if (lineDuration <= 0.001)
                                        return 0;
                                    var speedDuration = maxOffset / 50;
                                    var scrollDuration = Math.min(speedDuration, lineDuration * 0.9);
                                    if (scrollDuration <= 0.001)
                                        return -maxOffset;
                                    var elapsed = widget.smoothTime - start;
                                    if (elapsed < 0) return 0;
                                    if (elapsed >= scrollDuration) return -maxOffset;
                                    var p = elapsed / scrollDuration;
                                    return -maxOffset * p;
                                }
                                y: (lyricLayer.height - wordInRow.implicitHeight) / 2

                                Repeater {
                                    model: widget.wordList ? widget.wordList : []
                                    delegate: wordDelegate
                                }
                            }

                            transform: Scale {
                                yScale: widget.wordInScaleY
                                origin.x: wordInLayer.width / 2
                                origin.y: wordInLayer.height / 2
                            }
                        }
                    }
                }

                Text {
                    id: translationText
                    visible: widget.showTranslation && widget.translatedText !== ""
                    width: parent.width
                    text: widget.translatedText
                    color: widget.unplayedColor
                    opacity: 0.85
                    font.pixelSize: widget.translationFontSize
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    horizontalAlignment: widget.textAlign === "right" ? Text.AlignRight : (widget.textAlign === "center" ? Text.AlignHCenter : Text.AlignLeft)
                }
            }
        }
    }
}
