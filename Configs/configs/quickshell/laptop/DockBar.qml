// Horizontal top dock bar -- moved from the original vertical "Dock
// Rail" mockup per request, thinned down, and given the same opacity
// Hyprland's own window_rule applies to focused windows (0.9) so it
// reads as part of the same translucent-window look rather than a
// solid, un-transparent strip.
//
// Layout, left to right: workspaces / (centered) clock / volume,
// network, bluetooth, date, notifications.
//
// The four popup panels are NOT declared here anymore -- see shell.qml's
// header comment: nesting multiple PanelWindows as children of another
// PanelWindow was unreliable on real hardware (intermittent "X is not a
// type" errors, always one of the later-declared nested windows). They're
// now top-level siblings in shell.qml, coordinated through DockState.qml.
//
// Same multi-monitor-safe screen pattern as the other HyKr quickshell
// configs (wallpaper-picker, hykr): PanelWindow needs an explicit
// screen or it can silently fail to attach to any output at all.
//
// Every icon glyph below is written as a \u/\u{} JS escape rather than
// typed directly -- confirmed via byte inspection (od -c) that typing
// these Nerd Font codepoints directly into this file previously
// produced literally empty strings, particularly the ones above
// U+FFFF (volume, bluetooth). Codepoints reused from this repo's own
// waybar/swaync configs for visual consistency.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./services" as Services

PanelWindow {
    id: root

    required property var modelData
    readonly property var targetScreen: modelData

    readonly property int barHeight: 34

    screen: targetScreen
    color: "transparent"
    implicitHeight: barHeight
    exclusiveZone: barHeight

    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "laptop-dock"

    readonly property var workspaceIds: [1, 2, 3, 4, 5]
    readonly property var monitorWorkspaces: Hyprland.workspaces
        ? Hyprland.workspaces.values.filter(w => w.monitor && w.monitor.name === root.targetScreen.name)
        : []
    readonly property int activeWorkspaceId: {
        const active = monitorWorkspaces.find(w => w.active);
        return active ? active.id : -1;
    }

    // Background only -- alpha lives in the color itself (not the
    // Rectangle's opacity property), because opacity cascades to
    // children in Qt Quick. It was set on this Rectangle while the
    // RowLayout/clock were declared INSIDE it, so every icon and text
    // label was also rendering at 90% opacity instead of just the
    // background showing wallpaper through -- reported as "no
    // transparency" since a slightly-faded bar reads the same as an
    // opaque one at a glance. Content now lives as siblings below,
    // full opacity, on top of this.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.039, 0.078, 0.071, 0.55) // #0a1412 at 55% alpha
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
    }

    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 18

            // ---- left: workspaces ----
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

            Item { Layout.fillWidth: true }

            // ---- right: volume, network, bluetooth, date, notifications ----
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 16

                Item {
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-md-volume_high / nf-md-volume_mute
                        text: Services.AudioService.muted ? "\u{F075F}" : "\u{F057E}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: DockState.isActive(root.targetScreen, "volume") ? "#c8102e" : "#9fb3ae"
                    }
                    TapHandler { onTapped: DockState.toggle(root.targetScreen, "volume") }
                }

                Item {
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-fa-wifi / nf-custom-ethernet / nf-md-network_off
                        text: Services.NetworkService.connectionType === "wifi" ? ""
                            : Services.NetworkService.connectionType === "ethernet" ? "" : ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: DockState.isActive(root.targetScreen, "network") ? "#c8102e" : "#9fb3ae"
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: DockState.toggle(root.targetScreen, "network")
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
                        // nf-md-bluetooth
                        text: "\u{F00AF}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: DockState.isActive(root.targetScreen, "bluetooth") ? "#c8102e"
                            : (Services.BluetoothService.powered ? "#9fb3ae" : "#5c6d6a")
                    }
                    TapHandler { onTapped: DockState.toggle(root.targetScreen, "bluetooth") }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.now, "ddd d")
                    color: "#c8d4d1"
                    font.pixelSize: 12
                    font.family: "monospace"
                }

                Item {
                    width: 20; height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        // nf-md-bell
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: DockState.isActive(root.targetScreen, "notifications") ? "#c8102e" : "#9fb3ae"
                    }
                    Rectangle {
                        visible: Services.NotificationService.unreadCount > 0
                        width: 6; height: 6; radius: 3
                        color: "#f87171"
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                    TapHandler { onTapped: DockState.toggle(root.targetScreen, "notifications") }
                }
            }
        }

        // ---- center: clock ----
        // A separate item anchored to the bar's true center, rather than
        // a RowLayout child -- the left (workspaces) and right (controls)
        // groups are different widths, so centering this within the
        // RowLayout's flexible space wouldn't land it in the middle of
        // the whole bar.
        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.now, "hh:mm")
            color: "#eaf0ee"
            font.pixelSize: 12
            font.family: "monospace"
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
}
