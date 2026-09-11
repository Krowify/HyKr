import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen
    property real barHeight: 34
    // Distance from the bar's right edge to roughly under the volume
    // icon -- the rightmost trio (volume/network/bluetooth) now sits on
    // the right side of the bar, so these panels hang from the right
    // edge instead of the left. See DockBar.qml for the icon order this
    // mirrors (bell/date/bluetooth/network/volume, right to left).
    property real rightOffset: 170

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 220
    implicitHeight: 96
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    anchors { top: true; right: true }
    margins { top: root.barHeight + 6; right: root.rightOffset }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#0d1a18"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Row {
                spacing: 8
                Text { text: "Volume"; color: "#eaf0ee"; font.pixelSize: 13; font.weight: Font.DemiBold }
                Text {
                    text: Services.AudioService.muted ? "muted" : Services.AudioService.volume + "%"
                    color: "#9fb3ae"
                    font.pixelSize: 12
                }
            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.1)

                Rectangle {
                    width: parent.width * (Services.AudioService.muted ? 0 : Services.AudioService.volume / 100)
                    height: parent.height
                    radius: 3
                    color: "#c8102e"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => Services.AudioService.setVolume(mouse.x / width * 100)
                }
            }

            Row {
                spacing: 10
                Rectangle {
                    width: 76; height: 24; radius: 8
                    color: Services.AudioService.muted ? "#c8102e" : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: Services.AudioService.muted ? "Unmute" : "Mute"
                        color: "#eaf0ee"
                        font.pixelSize: 11
                    }
                    TapHandler { onTapped: Services.AudioService.toggleMute() }
                }
            }
        }
    }
}
