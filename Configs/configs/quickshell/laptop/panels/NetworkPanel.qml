// Left-click target for the dock's network icon. Right-click bypasses
// this entirely and launches nm-connection-editor (see DockBar.qml) --
// this panel is ProtonVPN-only, matching the split the user asked for.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen
    property real topOffset: 110

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 230
    implicitHeight: 132
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

            Text { text: "ProtonVPN"; color: "#eaf0ee"; font.pixelSize: 13; font.weight: Font.DemiBold }

            Row {
                visible: Services.NetworkService.vpnAvailable
                spacing: 6
                Rectangle {
                    width: 7; height: 7; radius: 4; anchors.verticalCenter: parent.verticalCenter
                    color: Services.NetworkService.vpnConnected ? "#4ade80" : "#9fb3ae"
                }
                Text {
                    text: Services.NetworkService.vpnConnected
                        ? ("Connected - " + (Services.NetworkService.vpnServer || "unknown server"))
                        : "Not connected"
                    color: "#c8d4d1"
                    font.pixelSize: 12
                }
            }

            Text {
                visible: !Services.NetworkService.vpnAvailable
                text: "protonvpn-cli not found"
                color: "#9fb3ae"
                font.pixelSize: 12
            }

            Row {
                spacing: 8
                visible: Services.NetworkService.vpnAvailable

                Rectangle {
                    width: 96; height: 26; radius: 8
                    color: Services.NetworkService.vpnConnected ? Qt.rgba(1, 1, 1, 0.08) : "#c8102e"
                    Text {
                        anchors.centerIn: parent
                        text: Services.NetworkService.vpnConnected ? "Disconnect" : "Quick Connect"
                        color: "#eaf0ee"
                        font.pixelSize: 11
                    }
                    TapHandler {
                        onTapped: Services.NetworkService.vpnConnected
                            ? Services.NetworkService.vpnDisconnect()
                            : Services.NetworkService.vpnConnect()
                    }
                }
            }

            Text {
                text: "Right-click the network icon for Network Manager"
                color: "#6f8985"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}
