// Hyperspace's top bar: three floating islands -- workspaces (left), clock
// and date (centre), system cluster (right) -- with the wallpaper showing
// through above and between them.
//
// It is ONE layer surface, not three. Three PanelWindows would mean three
// layer-shell surfaces to keep in sync (and shell.qml's header explains how
// badly Quickshell takes to a pile of PanelWindows), so instead this window
// is full width and fully transparent, and the islands are just rounded
// Rectangles inside it. The theme's hyprland.lua.tpl blurs this namespace
// with ignore_alpha = 0.2, which is what keeps the blur on the islands
// (alpha 0.55) and off the transparent gaps.
//
// Every colour comes from Colors.qml -- i.e. from the wallpaper, via
// matugen on a theme apply or pywal on a wallpaper pick. Nothing in this
// file is a fixed brand colour, which is the difference between this dock
// and the Laptop one it grew out of.
//
// The four popup panels are NOT declared here -- see shell.qml's header
// comment. DockBar only flips shared state (DockState.qml), handing over
// the tapped icon's distance from the screen's right edge so the panel can
// hang directly under it.
//
// Same multi-monitor-safe screen pattern as the other HyKr quickshell
// configs (wallpaper-picker, hykr, laptop): PanelWindow needs an explicit
// screen or it can silently fail to attach to any output at all.
//
// Every icon glyph is written as a \u/\u{} JS escape rather than typed
// directly -- confirmed via byte inspection (od -c) in the Laptop dock that
// typing these Nerd Font codepoints straight into a .qml file produced
// literally empty strings, particularly the ones above U+FFFF.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "./services" as Services

PanelWindow {
    id: root

    required property var modelData
    readonly property var targetScreen: modelData

    screen: targetScreen
    color: "transparent"
    implicitHeight: DockState.barHeight
    exclusiveZone: DockState.barHeight

    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "hyperspace-dock"

    readonly property var workspaceIds: [1, 2, 3, 4, 5]
    readonly property var monitorWorkspaces: Hyprland.workspaces ? Hyprland.workspaces.values.filter(w => w.monitor && w.monitor.name === root.targetScreen.name) : []
    readonly property int activeWorkspaceId: {
        const active = monitorWorkspaces.find(w => w.active);
        return active ? active.id : -1;
    }
    // Hyprland destroys a workspace once its last window closes, so "exists
    // in the workspace list" is the same thing as "has something on it" --
    // enough to light an otherwise-unlit pip without asking for window
    // counts.
    readonly property var occupiedIds: monitorWorkspaces.map(w => w.id)

    // Distance from the screen's right edge to the centre of an icon in the
    // right island, computed from that island's own live layout: its margin
    // and padding, plus however much of the row sits to the icon's right.
    // Called at tap time (not bound) so the panel that opens is placed
    // against the layout as it is at that moment -- the battery readout in
    // the same row changes width with the percentage, which would otherwise
    // put every panel a few pixels off.
    function anchorFor(item) {
        return DockState.islandMargin + DockState.islandPadding + (rightRow.width - (item.x + item.width / 2));
    }

    // ---- left island: workspaces ----
    Rectangle {
        id: leftIsland

        x: DockState.islandMargin
        y: DockState.topGap
        height: DockState.islandHeight
        width: workspaceRow.implicitWidth + DockState.islandPadding * 2
        radius: height / 2

        color: Colors.island
        border.width: 1
        border.color: Colors.hairline

        Row {
            id: workspaceRow
            anchors.centerIn: parent
            spacing: 7

            Repeater {
                model: root.workspaceIds

                delegate: Item {
                    readonly property bool isActive: modelData === root.activeWorkspaceId
                    readonly property bool isOccupied: root.occupiedIds.includes(modelData)

                    // The Item is full island height so the whole strip is a
                    // click target; only the pip inside it is painted.
                    width: isActive ? 20 : 7
                    height: leftIsland.height

                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    // The pip itself. Active stretches into a bar in the
                    // accent; occupied-but-not-active is a brighter dot than
                    // an empty one, so the bar says where you can go back to
                    // as well as where you are.
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 7
                        radius: height / 2
                        color: parent.isActive ? Colors.accent : parent.isOccupied ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : Colors.muted
                    }

                    TapHandler {
                        onTapped: Hyprland.dispatch("workspace " + modelData)
                    }
                }
            }
        }
    }

    // ---- centre island: clock + date ----
    Rectangle {
        id: centreIsland

        anchors.horizontalCenter: parent.horizontalCenter
        y: DockState.topGap
        height: DockState.islandHeight
        width: clockRow.implicitWidth + DockState.islandPadding * 2
        radius: height / 2

        color: Colors.island
        border.width: 1
        border.color: Colors.hairline

        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 9

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.now, "hh:mm")
                color: Colors.text
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.DemiBold
            }

            // Hairline divider rather than more whitespace: keeps the two
            // readouts from reading as one run of digits.
            Rectangle {
                width: 1
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.hairline
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.now, "ddd d MMM")
                color: Colors.textDim
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }
        }
    }

    // ---- right island: battery, volume, network, bluetooth, notifications ----
    //
    // Battery leads the row on purpose. It is the only item here whose width
    // changes at runtime (the percentage is always shown, not hidden behind a
    // hover like the Laptop dock's), and this island grows leftwards from the
    // screen's right edge -- so with battery first, nothing to its right ever
    // shifts when the number does.
    Rectangle {
        id: rightIsland

        x: parent.width - width - DockState.islandMargin
        y: DockState.topGap
        height: DockState.islandHeight
        width: rightRow.implicitWidth + DockState.islandPadding * 2
        radius: height / 2

        color: Colors.island
        border.width: 1
        border.color: Colors.hairline

        Row {
            id: rightRow
            anchors.centerIn: parent
            spacing: 14

            // Battery. Hidden outright on a machine with no battery (this
            // same shell also runs on a desktop's monitors) -- a Row skips
            // invisible children, so nothing else shifts.
            Row {
                id: batteryItem
                spacing: 5
                visible: Services.BatteryService.available
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // nf-md-battery_* and nf-md-battery_charging_*. Material
                    // Design's battery ramps are not evenly spaced -- the
                    // discharging set has every tenth, the charging set skips
                    // 10/50/70 -- so each threshold maps to the nearest glyph
                    // that actually exists rather than a computed decile.
                    text: {
                        const p = Services.BatteryService.percent;
                        if (Services.BatteryService.charging) {
                            if (p >= 95) return "\u{F0085}"; // charging_100
                            if (p >= 90) return "\u{F008B}"; // charging_90
                            if (p >= 80) return "\u{F008A}"; // charging_80
                            if (p >= 60) return "\u{F0089}"; // charging_60
                            if (p >= 40) return "\u{F0088}"; // charging_40
                            if (p >= 30) return "\u{F0087}"; // charging_30
                            if (p >= 20) return "\u{F0086}"; // charging_20
                            return "\u{F0084}"; // charging (generic)
                        }
                        if (p >= 95) return "\u{F0079}"; // battery (full)
                        if (p >= 90) return "\u{F0082}";
                        if (p >= 80) return "\u{F0081}";
                        if (p >= 70) return "\u{F0080}";
                        if (p >= 60) return "\u{F007F}";
                        if (p >= 50) return "\u{F007E}";
                        if (p >= 40) return "\u{F007D}";
                        if (p >= 30) return "\u{F007C}";
                        if (p >= 20) return "\u{F007B}";
                        if (p >= 10) return "\u{F007A}";
                        return "\u{F008E}"; // battery_outline (empty)
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: Services.BatteryService.low ? Colors.bad : Services.BatteryService.charging ? Colors.good : Colors.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.BatteryService.percent + "%"
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: Services.BatteryService.low ? Colors.bad : Colors.textDim
                }
            }

            Item {
                id: volumeItem
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    // nf-md-volume_high / nf-md-volume_mute
                    text: Services.AudioService.muted ? "\u{F075F}" : "\u{F057E}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: DockState.isActive(root.targetScreen, "volume") ? Colors.accent : Colors.icon
                }
                TapHandler {
                    onTapped: DockState.toggle(root.targetScreen, "volume", root.anchorFor(volumeItem))
                }
            }

            // Network. Left-click opens the ProtonVPN panel (which is also
            // where the current connection is named); right-click goes
            // straight to NetworkManager, same split as the Laptop dock.
            Item {
                id: networkItem
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    // nf-md-wifi / nf-md-ethernet / nf-md-wifi_off
                    text: Services.NetworkService.connectionType === "wifi" ? "\u{F05A9}"
                        : Services.NetworkService.connectionType === "ethernet" ? "\u{F0200}"
                        : "\u{F05AA}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: DockState.isActive(root.targetScreen, "network") ? Colors.accent : Services.NetworkService.vpnConnected ? Colors.good : Services.NetworkService.connectionType === "disconnected" ? Colors.bad : Colors.icon
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: DockState.toggle(root.targetScreen, "network", root.anchorFor(networkItem))
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: Services.NetworkService.openNetworkManager()
                }
            }

            Item {
                id: bluetoothItem
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    // nf-md-bluetooth / nf-md-bluetooth_connect / nf-md-bluetooth_off
                    text: !Services.BluetoothService.powered ? "\u{F00B2}" : Services.BluetoothService.connectedDevices.length > 0 ? "\u{F00B1}" : "\u{F00AF}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: DockState.isActive(root.targetScreen, "bluetooth") ? Colors.accent : !Services.BluetoothService.powered ? Colors.muted : Services.BluetoothService.connectedDevices.length > 0 ? Colors.good : Colors.icon
                }
                TapHandler {
                    onTapped: DockState.toggle(root.targetScreen, "bluetooth", root.anchorFor(bluetoothItem))
                }
            }

            Item {
                id: bellItem
                width: 20; height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    // nf-md-bell_off while DND is on, nf-md-bell otherwise --
                    // the bar says whether notifications are being held back
                    // without having to open the panel to find out.
                    text: Services.NotificationService.doNotDisturb ? "\u{F009B}" : "\u{F009A}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: DockState.isActive(root.targetScreen, "notifications") ? Colors.accent : Services.NotificationService.doNotDisturb ? Colors.muted : Colors.icon
                }
                Rectangle {
                    visible: Services.NotificationService.unreadCount > 0
                    width: 6; height: 6; radius: 3
                    color: Colors.accent
                    anchors.top: parent.top
                    anchors.right: parent.right
                }
                TapHandler {
                    onTapped: DockState.toggle(root.targetScreen, "notifications", root.anchorFor(bellItem))
                }
            }
        }
    }

    // The only consumers of clock.now render "hh:mm" and "ddd d MMM" --
    // neither changes more than once a minute, so a 1000 ms repeat would wake
    // the shell (and repaint) 60x more often than the display could possibly
    // differ. That is exactly the sort of idle wakeup that costs battery.
    // Instead: fire once, at the next minute boundary, then re-arm for the
    // following one. `repeat: false` plus a recomputed interval keeps it
    // aligned to :00 seconds rather than drifting by however long the shell
    // took to start.
    Timer {
        id: clock
        property date now: new Date()

        function msToNextMinute() {
            const d = new Date();
            return 60000 - (d.getSeconds() * 1000 + d.getMilliseconds());
        }

        interval: msToNextMinute()
        running: true
        repeat: false
        onTriggered: {
            now = new Date();
            interval = msToNextMinute();
            restart();
        }
    }
}
