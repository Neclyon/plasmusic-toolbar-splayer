import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: compact

    readonly property bool horizontal: widget.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool fillAvailableSpace: plasmoid.configuration.fillAvailableSpace

    Layout.preferredWidth: splayerContent.implicitWidth
    Layout.preferredHeight: splayerContent.implicitHeight
    Layout.minimumWidth: splayerContent.Layout.minimumWidth
    Layout.minimumHeight: splayerContent.Layout.minimumHeight
    Layout.fillHeight: horizontal || fillAvailableSpace
    Layout.fillWidth: !horizontal || fillAvailableSpace

    MouseAreaWithWheelHandler {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        propagateComposedEvents: true

        onClicked: (mouse) => {
            switch (mouse.button) {
            case Qt.MiddleButton:
                widget.togglePlayback()
                break
            case Qt.BackButton:
                if (widget.splayerControlsAvailable || player.canGoPrevious) {
                    widget.previousTrack();
                }
                break
            case Qt.ForwardButton:
                if (widget.splayerControlsAvailable || player.canGoNext) {
                    widget.nextTrack();
                }
                break
            default:
                if (mouse.modifiers & Qt.ControlModifier) {
                    if (player.canRaise) player.raise()
                } else {
                    widget.expanded = !widget.expanded;
                }
            }
        }

        onWheelUp: {
            player.changeVolume(plasmoid.configuration.volumeStep / 100, true);
        }

        onWheelDown: {
            player.changeVolume(-plasmoid.configuration.volumeStep / 100, true);
        }
    }

    CompactContent {
        id: splayerContent
        anchors.fill: parent
    }
}
