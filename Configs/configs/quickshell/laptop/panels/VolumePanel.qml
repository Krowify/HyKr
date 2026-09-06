import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen
    property real topOffset: 60

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 220
    implicitHeight: 96
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    anchors { top: true; left: true }
    margins { top: root.topOffset; left: 58 }

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
