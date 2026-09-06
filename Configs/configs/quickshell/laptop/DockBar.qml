// Vertical dock rail -- "Option 1" from the laptop-shell-concepts mockup.
// Same multi-monitor-safe screen pattern as the other HyKr quickshell
// configs (wallpaper-picker, hykr): PanelWindow needs an explicit screen
// or it can silently fail to attach to any output at all.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./services" as Services
import "./panels"

PanelWindow {
    id: root

    required property var modelData
    readonly property var targetScreen: modelData
    property string activePanel: "" // "" | "volume" | "network" | "bluetooth" | "notifications"

    screen: targetScreen
    color: "transparent"
    implicitWidth: 52
    exclusiveZone: 52

    anchors { top: true; bottom: true; left: true }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "laptop-dock"

    function togglePanel(name) {
        root.activePanel = root.activePanel === name ? "" : name;
    }

    readonly property var workspaceIds: [1, 2, 3, 4, 5]
    readonly property var monitorWorkspaces: Hyprland.workspaces
        ? Hyprland.workspaces.values.filter(w => w.monitor && w.monitor.name === root.targetScreen.name)
        : []
    readonly property int activeWorkspaceId: {
        const active = monitorWorkspaces.find(w => w.active);
        return active ? active.id : -1;
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a1412"
        opacity: 0.92
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            spacing: 16

            // ---- workspaces ----
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 7

                Repeater {
                    model: root.workspaceIds
                    delegate: Rectangle {
                        readonly property bool isActive: modelData === root.activeWorkspaceId
                        width: isActive ? 8 : 6
                        height: isActive ? 18 : 6
                        radius: isActive ? 4 : 3
                        color: isActive ? "#c8102e" : Qt.rgba(1, 1, 1, 0.22)

                        Behavior on height { NumberAnimation { duration: 120 } }

                        TapHandler {
                            onTapped: Hyprland.dispatch("workspace " + modelData)
                        }
                    }
                }
            }

            // ---- quick controls ----
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                topPadding: 6

                Item {
                    width: 28; height: 20
                    Text {
                        anchors.centerIn: parent
                        text: Services.AudioService.muted ? "" : ""
                        font.pixelSize: 15
                        color: root.activePanel === "volume" ? "#c8102e" : "#9fb3ae"
                    }
                    TapHandler { onTapped: root.togglePanel("volume") }
                }

                Item {
                    width: 28; height: 20
                    Text {
                        anchors.centerIn: parent
                        text: Services.NetworkService.connectionType === "wifi" ? ""
                            : Services.NetworkService.connectionType === "ethernet" ? "" : ""
                        font.pixelSize: 15
                        color: root.activePanel === "network" ? "#c8102e" : "#9fb3ae"
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.togglePanel("network")
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: Services.NetworkService.openNetworkManager()
                    }
                }

                Item {
                    width: 28; height: 20
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 15
                        color: root.activePanel === "bluetooth" ? "#c8102e"
                            : (Services.BluetoothService.powered ? "#9fb3ae" : "#5c6d6a")
                    }
                    TapHandler { onTapped: root.togglePanel("bluetooth") }
                }
            }

            Item { Layout.fillHeight: true } // pushes the group below to the bottom of the rail

            // ---- notifications + clock ----
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Item {
                    width: 28; height: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 15
                        color: root.activePanel === "notifications" ? "#c8102e" : "#9fb3ae"
                    }
                    Rectangle {
                        visible: Services.NotificationService.unreadCount > 0
                        width: 6; height: 6; radius: 3
                        color: "#f87171"
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                    TapHandler { onTapped: root.togglePanel("notifications") }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    // rotation is a transform, not a layout property -- a
                    // plain rotated Text keeps its unrotated (wide, short)
                    // bounding box for layout purposes, which would
                    // overlap neighbours in this narrow column. Each Text
                    // sits in an Item pre-sized to its ROTATED footprint
                    // (swapped width/height) so the Column reserves the
                    // right space.
                    Item {
                        width: 16; height: 34
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.now, "hh:mm")
                            color: "#eaf0ee"
                            font.pixelSize: 11
                            font.family: "monospace"
                            rotation: -90
                        }
                    }
                    Item {
                        width: 14; height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.now, "ddd d")
                            color: "#6f8985"
                            font.pixelSize: 9
                            font.family: "monospace"
                            rotation: -90
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: clock
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }

    VolumePanel { anchorScreen: root.targetScreen; visible: root.activePanel === "volume"; topOffset: 60 }
    NetworkPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "network"; topOffset: 100 }
    BluetoothPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "bluetooth"; topOffset: 140 }
    NotificationCenterPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "notifications" }
}
