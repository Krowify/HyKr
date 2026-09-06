// Horizontal top dock bar -- moved from the original vertical "Dock
// Rail" mockup per request, thinned down, and given the same opacity
// Hyprland's own window_rule applies to focused windows (0.9) so it
// reads as part of the same translucent-window look rather than a
// solid, un-transparent strip.
//
// Same multi-monitor-safe screen pattern as the other HyKr quickshell
// configs (wallpaper-picker, hykr): PanelWindow needs an explicit
// screen or it can silently fail to attach to any output at all.
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

    readonly property int barHeight: 34

    screen: targetScreen
    color: "transparent"
    implicitHeight: barHeight
    exclusiveZone: barHeight

    anchors { top: true; left: true; right: true }

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
        opacity: 0.9 // matches hyprland.lua.tpl's active_opacity -- see apply-theme.sh
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 18

            // ---- workspaces ----
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 7

                Repeater {
                    model: root.workspaceIds
                    delegate: Rectangle {
                        readonly property bool isActive: modelData === root.activeWorkspaceId
                        width: isActive ? 18 : 6
                        height: isActive ? 8 : 6
                        radius: isActive ? 4 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: isActive ? "#c8102e" : Qt.rgba(1, 1, 1, 0.22)

                        Behavior on width { NumberAnimation { duration: 120 } }

                        TapHandler {
                            onTapped: Hyprland.dispatch("workspace " + modelData)
                        }
                    }
                }
            }

            // ---- quick controls ----
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 16

                Item {
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-md-volume_high / nf-md-volume_mute -- same
                        // glyphs swaync's own volume/mute widgets use.
                        text: Services.AudioService.muted ? "\u{F075F}" : "\u{F057E}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.activePanel === "volume" ? "#c8102e" : "#9fb3ae"
                    }
                    TapHandler { onTapped: root.togglePanel("volume") }
                }

                Item {
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-fa-wifi / nf-custom-ethernet / nf-md-network_off
                        // -- same glyphs the existing waybar network module uses.
                        text: Services.NetworkService.connectionType === "wifi" ? ""
                            : Services.NetworkService.connectionType === "ethernet" ? "" : ""
                        font.family: "JetBrainsMono Nerd Font"
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
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-md-bluetooth -- same glyph waybar's bluetooth
                        // module uses for format-on.
                        text: "\u{F00AF}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.activePanel === "bluetooth" ? "#c8102e"
                            : (Services.BluetoothService.powered ? "#9fb3ae" : "#5c6d6a")
                    }
                    TapHandler { onTapped: root.togglePanel("bluetooth") }
                }
            }

            Item { Layout.fillWidth: true } // pushes the group below to the right end of the bar

            // ---- notifications + clock ----
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 14

                Item {
                    width: 20; height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        // nf-md-bell -- same glyph waybar's
                        // custom/notification module uses.
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
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

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.now, "hh:mm") + "  ·  " + Qt.formatDateTime(clock.now, "ddd d")
                    color: "#eaf0ee"
                    font.pixelSize: 12
                    font.family: "monospace"
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

    VolumePanel { anchorScreen: root.targetScreen; visible: root.activePanel === "volume"; barHeight: root.barHeight; xOffset: 60 }
    NetworkPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "network"; barHeight: root.barHeight; xOffset: 100 }
    BluetoothPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "bluetooth"; barHeight: root.barHeight; xOffset: 140 }
    NotificationCenterPanel { anchorScreen: root.targetScreen; visible: root.activePanel === "notifications"; barHeight: root.barHeight }
}
