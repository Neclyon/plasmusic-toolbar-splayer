import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property int cfg_fixedWidth
    property int cfg_fixedHeight
    property int cfg_fontSize
    property string cfg_fontFamily
    property string cfg_textAlign
    property bool cfg_showBackground
    property bool cfg_useCustomColors
    property color cfg_customPlayedColor
    property color cfg_customUnplayedColor
    property bool cfg_showTranslation
    property int cfg_translationFontSize
    property int cfg_lineSpacing
    property string cfg_animationType
    property bool cfg_showCover
    property string cfg_coverAlign
    property int cfg_coverSize
    property int cfg_coverRadius
    property int cfg_autoHideDelay

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Display Contents")
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            text: i18n("Show translation (if available)")
            checked: cfg_showTranslation
            onToggled: cfg_showTranslation = checked
        }

        CheckBox {
            text: i18n("Show cover art")
            checked: cfg_showCover
            onToggled: cfg_showCover = checked
        }

        CheckBox {
            text: i18n("Show background")
            checked: cfg_showBackground
            onToggled: cfg_showBackground = checked
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Layout Settings")
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            id: alignCombo
            Kirigami.FormData.label: i18n("Text alignment:")
            textRole: "text"
            model: [
                { "text": i18n("Center"), "value": "center" },
                { "text": i18n("Left"), "value": "left" },
                { "text": i18n("Right"), "value": "right" }
            ]
            onActivated: cfg_textAlign = model[currentIndex].value
            Component.onCompleted: {
                var v = cfg_textAlign || "center"
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === v) {
                        currentIndex = i
                        return
                    }
                }
                currentIndex = 0
            }
        }

        ComboBox {
            id: coverAlignCombo
            Kirigami.FormData.label: i18n("Cover position:")
            textRole: "text"
            enabled: cfg_showCover
            model: [
                { "text": i18n("Left"), "value": "left" },
                { "text": i18n("Right"), "value": "right" }
            ]
            onActivated: cfg_coverAlign = model[currentIndex].value
            Component.onCompleted: {
                var v = cfg_coverAlign || "left"
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === v) {
                        currentIndex = i
                        return
                    }
                }
                currentIndex = 0
            }
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Cover size:")
            from: 16
            to: 128
            stepSize: 2
            value: cfg_coverSize
            onValueModified: cfg_coverSize = value
            textFromValue: function(value) { return value + " px" }
            enabled: cfg_showCover
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Fixed width (0 = auto):")
            from: 0
            to: 2000
            stepSize: 10
            value: cfg_fixedWidth
            onValueModified: cfg_fixedWidth = value
            textFromValue: function(value) { return value === 0 ? i18n("Auto") : value + " px" }
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Fixed height (0 = auto):")
            from: 0
            to: 200
            stepSize: 2
            value: cfg_fixedHeight
            onValueModified: cfg_fixedHeight = value
            textFromValue: function(value) { return value === 0 ? i18n("Auto") : value + " px" }
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Line spacing:")
            from: -20
            to: 100
            stepSize: 1
            value: cfg_lineSpacing
            onValueModified: cfg_lineSpacing = value
            textFromValue: function(value) { return value + " px" }
            visible: cfg_showTranslation
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Appearance Customizations")
            Kirigami.FormData.isSection: true
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Cover corner radius:")
            from: 0
            to: 64
            stepSize: 1
            value: cfg_coverRadius
            onValueModified: cfg_coverRadius = value
            textFromValue: function(value) { return value + " px" }
            enabled: cfg_showCover
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font:")
            TextField {
                text: cfg_fontFamily || i18n("Default font")
                readOnly: true
                Layout.fillWidth: true
            }
            Button {
                text: i18n("Select...")
                onClicked: {
                    if (cfg_fontFamily) fontDialog.currentFont.family = cfg_fontFamily
                    fontDialog.open()
                }
            }
            Button {
                icon.name: "edit-clear"
                visible: cfg_fontFamily !== ""
                onClicked: cfg_fontFamily = ""
                ToolTip.text: i18n("Reset to default font")
                ToolTip.visible: hovered
            }
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Font size:")
            from: 8
            to: 72
            stepSize: 1
            value: cfg_fontSize
            onValueModified: cfg_fontSize = value
            textFromValue: function(value) { return value + " pt" }
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Translation font size (0 = auto):")
            from: 0
            to: 72
            stepSize: 1
            value: cfg_translationFontSize
            onValueModified: cfg_translationFontSize = value
            textFromValue: function(value) { return value === 0 ? i18n("Auto") : value + " pt" }
            visible: cfg_showTranslation
        }

        SpinBox {
            Kirigami.FormData.label: i18n("Auto-hide after pause (seconds, 0 = off):")
            from: 0
            to: 300
            stepSize: 1
            value: cfg_autoHideDelay
            onValueModified: cfg_autoHideDelay = value
            textFromValue: function(value) { return value === 0 ? i18n("Off") : value + " s" }
        }

        ComboBox {
            id: animCombo
            Kirigami.FormData.label: i18n("Transition animation:")
            textRole: "text"
            model: [
                { "text": i18n("Scale + Fade"), "value": "scale" },
                { "text": i18n("Fade only"), "value": "fade" },
                { "text": i18n("Vertical flip"), "value": "flip" },
                { "text": i18n("None"), "value": "none" }
            ]
            onActivated: cfg_animationType = model[currentIndex].value
            Component.onCompleted: {
                var v = cfg_animationType || "scale"
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === v) {
                        currentIndex = i
                        return
                    }
                }
                currentIndex = 0
            }
        }

        CheckBox {
            text: i18n("Use custom colors")
            checked: cfg_useCustomColors
            onToggled: cfg_useCustomColors = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Colors:")
            enabled: cfg_useCustomColors
            Label { text: i18n("Played:") }
            Rectangle {
                width: 30; height: 20
                color: cfg_customPlayedColor
                border.width: 1; border.color: "gray"
                MouseArea {
                    anchors.fill: parent
                    onClicked: playedColorDialog.open()
                }
            }
            Item { width: 10 }
            Label { text: i18n("Unplayed:") }
            Rectangle {
                width: 30; height: 20
                color: cfg_customUnplayedColor
                border.width: 1; border.color: "gray"
                MouseArea {
                    anchors.fill: parent
                    onClicked: unplayedColorDialog.open()
                }
            }
        }

        Label {
            text: i18n("Click color swatch to change")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            visible: cfg_useCustomColors
        }
    }

    FontDialog {
        id: fontDialog
        title: i18n("Select Font")
        onAccepted: { cfg_fontFamily = currentFont.family }
    }

    ColorDialog {
        id: playedColorDialog
        title: i18n("Select played color")
        selectedColor: cfg_customPlayedColor
        onAccepted: cfg_customPlayedColor = selectedColor
    }

    ColorDialog {
        id: unplayedColorDialog
        title: i18n("Select unplayed color")
        selectedColor: cfg_customUnplayedColor
        onAccepted: cfg_customUnplayedColor = selectedColor
    }
}
