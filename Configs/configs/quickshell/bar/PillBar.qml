// The "pill" bar style: one rounded island in the middle of the top edge
// holding everything -- workspaces, volume, network, bluetooth, clock, tray,
// notifications -- with hairline dividers between the modules.
//
// This is the waybar bar that Arch, Dynamic, Everforest and Graphite
// used to run (theme-switcher/themes/*/templates/waybar/, removed when they
// moved here), redone in Quickshell. Same geometry (10px down from the edge,
// 34px tall, centred), same module order, same labels, but:
//
//   - the icons open this shell's own popup panels instead of shelling out
//     to pavucontrol / blueman-manager, and the bell is this shell's own
//     notification centre instead of swaync's;
//   - workspaces show 1-5 always, plus any higher one that has windows on
//     it, and an occupied workspace reads brighter than an empty one;
//   - every colour comes from Colors.qml, i.e. from the theme (or the
//     wallpaper, for Dynamic) -- with DockState.colorful each module gets
//     its own role colour, the way Arch's waybar bar looked.
//
// Like the other bars, it is ONE full-width transparent layer surface with
// the pill drawn inside it; every theme's hyprland.lua.tpl blurs this
// namespace with ignore_alpha = 0.2, which keeps the blur on the pill and off
// the empty strip either side.
//
// Every icon glyph is a \u{} JS escape rather than a typed character --
// typing Nerd Font codepoints straight into a .qml file has been confirmed
// (od -c) to produce literally empty strings, particularly above U+FFFF.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
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
    WlrLayershell.namespace: "hykr-bar"


    // A module's colour: its own role colour when the theme asks for a
    // colourful bar, the plain foreground otherwise -- and the accent for
    // whichever module's panel is open, either way.
    function tint(roleColour, panel) {
        if (panel !== undefined && DockState.isActive(root.targetScreen, panel))
            return Colors.accent;
        return DockState.colorful ? roleColour : Colors.text;
    }

    // Distance from the screen's right edge to the centre of an item, for the
    // popup panels to hang under. This window spans the whole output from
    // x = 0, so window x is screen x. Called at tap time, not bound, so it
    // reflects the pill as it is right then (its width moves with the volume
    // readout and the network name).
    function anchorFor(item) {
        const centre = item.mapToItem(null, item.width / 2, 0);
        return root.width - centre.x;
    }

    // ---- workspaces ----

    readonly property var monitorWorkspaces: Hyprland.workspaces ? Hyprland.workspaces.values.filter(w => w.monitor && w.monitor.name === root.targetScreen.name) : []
    readonly property int activeWorkspaceId: {
        const active = monitorWorkspaces.find(w => w.active);
        return active ? active.id : -1;
    }
    // Hyprland destroys a workspace once its last window closes, so "in the
    // list" means "has something on it".
    readonly property var occupiedIds: monitorWorkspaces.map(w => w.id)
    // 1-5 always (somewhere to click to), plus anything above 5 that exists
    // right now -- waybar listed whatever existed, and Super+6..0 are bound,
    // so a window parked on 7 shouldn't be invisible here. Special (negative)
    // workspaces are left out, as waybar did.
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5];
        for (const id of root.occupiedIds) {
            if (id > 0 && ids.indexOf(id) < 0)
                ids.push(id);
        }
        return ids.sort((a, b) => a - b);
    }

    // ---- building blocks ----

    // Thin vertical rule between modules -- waybar drew these as a 1px
    // border-left on every module after the workspaces.
    component Divider: Rectangle {
        width: 1
        height: 14
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: Colors.hairline
    }

    // An icon + label module. Clicks, scrolls and hovers are all reported
    // back through signals so each use site says what it does in one place.
    component Module: Item {
        id: module

        property string icon: ""
        property string label: ""
        property color tint: Colors.text

        signal leftClicked()
        signal rightClicked()
        signal middleClicked()
        signal scrolled(int direction)

        implicitWidth: row.implicitWidth + 20
        width: implicitWidth
        height: parent ? parent.height : 0

        Row {
            id: row
            anchors.centerIn: parent
            spacing: module.icon.length > 0 && module.label.length > 0 ? 7 : 0

            Text {
                visible: module.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: module.icon
                color: module.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
            Text {
                visible: module.label.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: module.label
                color: module.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
        }

        // A faint wash under the pointer, so it's clear what's clickable --
        // waybar's default hover, toned to the theme.
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            radius: height / 2
            color: Colors.mutedFill
            visible: mouse.containsMouse
            z: -1
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: ev => {
                if (ev.button === Qt.RightButton)
                    module.rightClicked();
                else if (ev.button === Qt.MiddleButton)
                    module.middleClicked();
                else
                    module.leftClicked();
            }
            onWheel: ev => module.scrolled(ev.angleDelta.y > 0 ? 1 : -1)
        }
    }

    // ---- the pill ----

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: DockState.pillTopGap
        height: DockState.pillHeight
        // Never wider than the screen, less a margin each side: a narrow
        // output clips the row rather than pushing the pill off the edges.
        width: Math.min(content.implicitWidth + 12, root.width - DockState.islandMargin * 2)
        radius: height / 2
        clip: true

        color: Colors.island
        border.width: 1
        border.color: Colors.hairline

        Row {
            id: content
            anchors.centerIn: parent
            height: parent.height
            spacing: 0

            // ---- workspaces ----
            Row {
                id: workspaceRow
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
                rightPadding: 8
                spacing: 4

                Repeater {
                    model: root.workspaceIds

                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool isActive: modelData === root.activeWorkspaceId
                        readonly property bool isOccupied: root.occupiedIds.indexOf(modelData) >= 0

                        anchors.verticalCenter: parent.verticalCenter
                        // The active workspace stretches into a filled pill,
                        // as waybar's button.active did (min-width 32px).
                        width: isActive ? 32 : Math.max(20, wsLabel.implicitWidth + 10)
                        height: isActive ? 20 : 18
                        radius: height / 2

                        color: isActive ? Colors.accent : wsMouse.containsMouse ? Colors.mutedFill : "transparent"
                        border.width: isActive ? 0 : 2
                        border.color: isOccupied ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45) : Colors.mutedFill

                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: parent.modelData
                            // On the accent fill the label takes the theme's
                            // background, so it reads as cut out of the pill.
                            color: parent.isActive ? Colors.bg : parent.isOccupied ? Colors.text : Colors.textDim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: parent.isActive ? Font.Bold : Font.Normal
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + parent.modelData)
                        }
                    }
                }
            }

            Divider {}

            // ---- volume ----
            Module {
                id: volumeModule
                // nf-fa-volume_off / _down / _up by level, nf-md-volume_off
                // when muted -- the same glyphs waybar's format-icons used.
                icon: Services.AudioService.muted ? "\u{F075F}"
                    : Services.AudioService.volume < 34 ? ""
                    : Services.AudioService.volume < 67 ? "" : ""
                label: Services.AudioService.muted ? "Muted" : Services.AudioService.volume + "%"
                tint: root.tint(Colors.orange, "volume")
                onLeftClicked: DockState.toggle(root.targetScreen, "volume", root.anchorFor(volumeModule))
                onRightClicked: Services.AudioService.toggleMute()
                // The full mixer is still one click away, just not the
                // primary one any more.
                onMiddleClicked: Quickshell.execDetached(["pavucontrol"])
                onScrolled: dir => Services.AudioService.stepVolume(dir * 5)
            }

            Divider {}

            // ---- network ----
            Module {
                id: networkModule
                readonly property string type: Services.NetworkService.connectionType
                readonly property string name: Services.NetworkService.connectionName
                // nf-fa-wifi / nf-md-ethernet / nf-md-wifi_off
                icon: type === "wifi" ? "" : type === "ethernet" ? "\u{F0200}" : "\u{F05AA}"
                // Long SSIDs are trimmed so one coffee-shop network name
                // can't stretch the pill across the screen.
                label: type === "wifi" ? (name.length > 18 ? name.slice(0, 17) + "…" : name)
                    : type === "ethernet" ? "Wired" : "Offline"
                tint: type === "disconnected" ? Colors.bad : root.tint(Colors.good, "network")
                onLeftClicked: DockState.toggle(root.targetScreen, "network", root.anchorFor(networkModule))
                onRightClicked: Services.NetworkService.openNetworkManager()
            }

            Divider {}

            // ---- bluetooth ----
            Module {
                id: bluetoothModule
                readonly property bool connected: Services.BluetoothService.connectedDevices.length > 0
                // nf-fa-bluetooth / nf-md-bluetooth_off
                icon: Services.BluetoothService.powered ? "" : "\u{F00B2}"
                label: connected && Services.BluetoothService.connectedDevices.length === 1 && Services.BluetoothService.connectedDevices[0].name
                    ? Services.BluetoothService.connectedDevices[0].name
                    : "BT"
                tint: !Services.BluetoothService.powered && !DockState.isActive(root.targetScreen, "bluetooth")
                    ? Colors.textDim
                    : root.tint(Colors.blue, "bluetooth")
                onLeftClicked: DockState.toggle(root.targetScreen, "bluetooth", root.anchorFor(bluetoothModule))
                onRightClicked: Services.BluetoothService.togglePower()
            }

            Divider {}

            // ---- clock ----
            Module {
                // nf-fa-calendar date | nf-fa-clock_o time, as waybar's
                // "  %d %b %Y |   %H:%M" format had it.
                icon: ""
                label: Qt.formatDateTime(clock.now, "dd MMM yyyy") + "  |    " + Qt.formatDateTime(clock.now, "hh:mm")
                tint: DockState.colorful ? Colors.accent : Colors.text
            }

            // ---- tray ----
            // Only takes up room (and a divider) when something is docked
            // there.
            Divider { visible: trayRepeater.count > 0 }

            Row {
                visible: trayRepeater.count > 0
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
                rightPadding: 10
                spacing: 10

                Repeater {
                    id: trayRepeater
                    model: SystemTray.items

                    delegate: Item {
                        id: trayItem
                        required property var modelData
                        width: 16
                        height: 16
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                        IconImage {
                            anchors.fill: parent
                            source: trayItem.modelData.icon
                            asynchronous: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ev => {
                                const item = trayItem.modelData;
                                if (ev.button === Qt.MiddleButton) {
                                    item.secondaryActivate();
                                } else if (ev.button === Qt.LeftButton && !item.onlyMenu) {
                                    item.activate();
                                } else if (item.hasMenu) {
                                    // Hang the item's own menu just under the
                                    // pill, below the icon that opened it.
                                    const p = trayItem.mapToItem(null, 0, trayItem.height);
                                    item.display(root, p.x, DockState.barHeight + 4);
                                }
                            }
                        }
                    }
                }
            }

            Divider {}

            // ---- notifications ----
            Module {
                id: bellModule
                // nf-md-bell / nf-md-bell_off while Do Not Disturb is on
                icon: Services.NotificationService.doNotDisturb ? "\u{F009B}" : "\u{F009A}"
                tint: Services.NotificationService.doNotDisturb && !DockState.isActive(root.targetScreen, "notifications")
                    ? Colors.textDim
                    : root.tint(Colors.bad, "notifications")
                onLeftClicked: DockState.toggle(root.targetScreen, "notifications", root.anchorFor(bellModule))
                onRightClicked: Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb

                // Unread dot, top-right of the glyph.
                Rectangle {
                    visible: Services.NotificationService.unreadCount > 0
                    width: 6; height: 6; radius: 3
                    color: Colors.accent
                    x: parent.width / 2 + 3
                    y: parent.height / 2 - 9
                }
            }
        }
    }

    // Minute-aligned clock, same as the other bars: nothing here shows
    // seconds, so waking every second would be 60x more repaints than the
    // display could ever differ by.
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
