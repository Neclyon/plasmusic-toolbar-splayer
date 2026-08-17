import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM


KCM.SimpleKCM {
    id: generalConfigPage

    property alias cfg_volumeStep: volumeStepSpinbox.value
    property alias cfg_noMediaText: noMediaText.text
    property alias cfg_showWhenNoMedia: showWhenNoMedia.checked
    property alias cfg_fillAvailableSpace: fillAvailableSpaceCheckbox.checked
    property alias cfg_hidePlayerControlBindsInHoverTooltip: hidePlayerControlBindsInHoverTooltip.checked
    property string cfg_wsUrl
    property int cfg_wsReconnectIntervalMs

    Kirigami.FormLayout {
        id: form

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Playback source")
        }

        TextField {
            Kirigami.FormData.label: i18n("WebSocket URL:")
            text: cfg_wsUrl
            onTextChanged: cfg_wsUrl = text
            placeholderText: "ws://localhost:25885"
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Reconnect interval (ms):")
            from: 500
            to: 60000
            stepSize: 500
            value: cfg_wsReconnectIntervalMs
            onValueModified: cfg_wsReconnectIntervalMs = value
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("No media found behavior")
        }

        CheckBox {
            id:showWhenNoMedia
            Kirigami.FormData.label: i18n("Show widget when no media found")
        }

        TextField {
            id: noMediaText
            Kirigami.FormData.label: i18n("Text displayed when no media found:")
            enabled: showWhenNoMedia.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Controls behaviour")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fill available space in the panel")
            CheckBox {
                id: fillAvailableSpaceCheckbox
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n(
                    "The widget fills all available width in the horizontal panel (or height in the vertical panel)."
                )
            }
        }

        CheckBox {
            id: hidePlayerControlBindsInHoverTooltip
            Kirigami.FormData.label: i18n("Hide player control keybinds in tooltip")
        }

        SpinBox {
            id: volumeStepSpinbox
            Kirigami.FormData.label: i18n("Volume step:")
            from: 1
            to: 100
            textFromValue: function(text) { return text + "%"; }
            valueFromText: function(value) { return parseInt(value); }
        }
    }

}
