import QtQuick 2.0
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "systemsettings"
        source: "config/General.qml"
    }
    ConfigCategory {
        name: i18n("Full View")
        icon: "preferences-system-windows-behavior"
        source: "config/Full.qml"
    }
    ConfigCategory {
        name: i18n("Panel View")
        icon: "org.kde.plasma.taskmanager"
        source: "config/PanelView.qml"
    }
}
