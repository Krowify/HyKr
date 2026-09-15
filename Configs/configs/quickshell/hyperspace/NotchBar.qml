// Hyperspace's "dynamic notch" bar: one capsule hanging from the top edge,
// clock and workspaces at rest, widening when something wants to tell you
// something -- the volume moved, a bluetooth device connected, the battery
// went low, a notification landed -- and collapsing again a couple of
// seconds later. Selected by DockState.barStyle; DockBar.qml (the three
// floating islands) is the other option and stays buildable.
//
// HOW IT FITS
//
// The capsule is laid out as three parts in one centred Row:
//
//     [ left wing ][ clock + workspaces ][ right wing ]
//
// The centre group is ALWAYS visible and never moves. Both wings are the
// same width as each other (wingWidth below takes the max of the two
// contents), and that width animates 0 -> wingWidth, so the capsule grows
// symmetrically around the clock instead of re-centring its contents and
// sliding the time across the screen every time it opens. Each wing clips
// its own content, so the icons emerge from behind the clock as the wing
// grows outward rather than being revealed mid-word.
//
// Nothing here animates the capsule's own width directly: the capsule is
// sized to its content row, so animating the two wing widths is what moves
// it, and there is exactly one animation driving the whole gesture. The
// width is clamped to the screen so a narrow display gets a capsule that
// stops at the edges rather than one that runs off them.
//
// The layer surface itself is full-width, transparent, and a FIXED 30px
// tall -- the same as the exclusive zone, so tiled windows sit right under
// the capsule and the surface never resizes as the notch opens (a
// layer-shell surface that resized every frame of the animation would make
// the compositor re-lay-out the whole output 60 times a second). The
// capsule only grows sideways, never down, which is what makes that
// possible.
//
// Every icon glyph is a \u{} JS escape rather than a typed character:
// typing these Nerd Font codepoints straight into a .qml file has been
// confirmed (od -c) to produce literally empty strings, particularly above
// U+FFFF.
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
    implicitHeight: DockState.notchHeight
    exclusiveZone: DockState.notchHeight

    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "hyperspace-notch"

    // ---- what's on screen ----

    readonly property var workspaceIds: [1, 2, 3, 4, 5]
    readonly property var monitorWorkspaces: Hyprland.workspaces ? Hyprland.workspaces.values.filter(w => w.monitor && w.monitor.name === root.targetScreen.name) : []
    readonly property int activeWorkspaceId: {
        const active = monitorWorkspaces.find(w => w.active);
        return active ? active.id : -1;
    }
    // Hyprland destroys a workspace once its last window closes, so "exists
    // in the workspace list" is the same thing as "has something on it".
    readonly property var occupiedIds: monitorWorkspaces.map(w => w.id)

    // ---- expansion ----

    // Open while the pointer is on it, while an event is still being shown,
    // and for as long as one of the popup panels is up -- collapsing the
    // notch out from under an open panel would leave the panel pointing at
    // nothing.
    readonly property bool panelOpen: DockState.activePanel !== "" && DockState.activeScreen === root.targetScreen
    readonly property bool expanded: hover.containsMouse || holdTimer.running || root.panelOpen

    // Which reading just changed, so the expanded row can point at it
    // instead of the notch just saying "something happened". Cleared when
    // the hold expires.
    property string highlight: ""

    // Every service populates its properties on its first poll, and those
    // first values are changes as far as a property-change handler is
    // concerned -- without this the notch would fling itself open two or
    // three times in the first seconds of every login. Nothing is treated
    // as an event until the services have settled.
    property bool settled: false

    function flash(what) {
        if (!root.settled)
            return;
        root.highlight = what;
        holdTimer.restart();
    }

    // Distance from the screen's right edge to the centre of an icon, for
    // the popup panels to hang under. mapToItem(null, ...) resolves to
    // window coordinates, and this window spans the whole output starting
    // at x = 0, so window x is screen x -- which keeps this correct however
    // the capsule and its wings are sized at the moment of the tap.
    function anchorFor(item) {
        const centre = item.mapToItem(null, item.width / 2, 0);
        return root.width - centre.x;
    }

    Timer {
        id: settleTimer
        interval: 2500
        running: true
        repeat: false
        onTriggered: root.settled = true
    }

    Timer {
        id: holdTimer
        interval: 2600
        repeat: false
        onTriggered: root.highlight = ""
    }

    // ---- event sources ----
    // Each of these is a property the bar already renders; watching them
    // costs nothing extra, and means the notch reacts to the same poll that
    // updates the reading rather than needing new signals in the services.

    // Read the level as the notch opens: the left wing shows the number, and
    // AudioService only polls it for whoever asks, so without this it renders
    // whatever the last poll left behind -- 0% until the volume panel has
    // been opened once.
    onExpandedChanged: if (root.expanded) Services.AudioService.refreshVolume()

    Connections {
        target: Services.AudioService
        // Not while the pointer is on the notch: it is already open and you
        // are already looking at the number, so holding it open for another
        // 2.6s after you move away adds nothing. That also keeps the read
        // above from registering as an event in its own right.
        function onVolumeChanged() { if (!hover.containsMouse) root.flash("volume"); }
        function onMutedChanged() { root.flash("volume"); }
    }

    Connections {
        target: Services.BatteryService
        // Not `percent`: that ticks every few points all day. The two
        // transitions worth interrupting you for are "you're now on
        // battery and low" and "you plugged it in".
        function onLowChanged() { root.flash("battery"); }
        function onChargingChanged() { root.flash("battery"); }
    }

    // A count, not the device list. BluetoothService now only reassigns
    // that list when it genuinely changes, but watching a `property var`
    // for "something happened" is the wrong shape regardless: an int
    // notifies when the number moves and never otherwise, which is exactly
    // the question being asked here. This pair was the bar opening itself
    // every 15 seconds with nobody touching anything.
    readonly property int btConnectedCount: Services.BluetoothService.connectedDevices.length
    onBtConnectedCountChanged: root.flash("bluetooth")

    Connections {
        target: Services.BluetoothService
        function onPoweredChanged() { root.flash("bluetooth"); }
    }

    Connections {
        target: Services.NetworkService
        function onConnectionTypeChanged() { root.flash("network"); }
        function onVpnConnectedChanged() { root.flash("network"); }
    }

    Connections {
        target: Services.NotificationService
        function onUnreadCountChanged() {
            // Only on arrival. Dismissing the last toast drops the count to
            // zero, which is not news.
            if (Services.NotificationService.unreadCount > 0)
                root.flash("notifications");
        }
    }

    // ---- the capsule ----

    Item {
        id: capsule

        // Content-sized, centred, and clamped so it can never run off a
        // narrow output. Nothing animates this directly -- the wing widths
        // below are the only animation, and the capsule follows them.
        readonly property int padding: 15
        readonly property int maxWidth: root.width - DockState.islandMargin * 2

        // Both wings take the width of the WIDER content, so the centre
        // group stays exactly centred in the capsule and the clock does not
        // shift by a pixel when the notch opens. Measured from the two
        // content rows rather than hardcoded, so editing either wing's
        // contents keeps that symmetry automatically.
        //
        // + 26 gives the wider wing 13px of clearance at each end. The
        // narrower one gets that plus half the difference at each end,
        // because its content is centred in the wing rather than pushed
        // against the clock -- otherwise every pixel by which the two wings
        // disagree would pool at one end of the capsule and read as a hole
        // rather than as padding.
        readonly property real wingWidth: Math.max(leftContent.implicitWidth, rightContent.implicitWidth) + 26

        width: Math.min(contentRow.implicitWidth + capsule.padding * 2, capsule.maxWidth)
        height: root.height
        x: (root.width - width) / 2
        clip: true

        // MouseArea rather than a pointer handler -- see
        // panels/NetworkPanel.qml for what that cost. acceptedButtons is
        // NoButton so it tracks the pointer for the expand without
        // swallowing clicks meant for the icons' TapHandlers in the wings.
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        // The rounded body, pushed up past the top of the clip rectangle so
        // its top corners fall outside and only the bottom two are rounded
        // -- the capsule reads as hanging off the screen edge rather than
        // floating just below it. Done by clipping rather than with
        // per-corner radii, which need a newer Qt than this has to assume.
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: -radius
            radius: 16
            // Same 0.55 alpha as the island bar and the Laptop dock, and the
            // theme's hyprland.lua.tpl blurs this namespace with
            // ignore_alpha = 0.2 -- above 0.55, so the capsule is blurred
            // while the transparent rest of the surface is left alone.
            color: Colors.island
            border.width: 1
            border.color: Colors.hairline
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 0

            // ---- left wing: volume, network, bluetooth ----
            Item {
                id: leftWing
                width: root.expanded ? capsule.wingWidth : 0
                height: capsule.height
                clip: true
                opacity: root.expanded ? 1 : 0

                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                // Centred in the wing, which is clipped and grows outward
                // from the clock -- so the icons emerge from behind the
                // centre group rather than being revealed mid-word.
                Row {
                    id: leftContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Item {
                        id: volumeItem
                        width: volumeRow.implicitWidth
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: volumeRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                // nf-md-volume_high / nf-md-volume_mute
                                text: Services.AudioService.muted ? "\u{F075F}" : "\u{F057E}"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: DockState.isActive(root.targetScreen, "volume") || root.highlight === "volume" ? Colors.accent : Colors.icon
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.AudioService.muted ? "muted" : Services.AudioService.volume + "%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: root.highlight === "volume" ? Colors.accent : Colors.textDim
                            }
                        }

                        TapHandler {
                            onTapped: DockState.toggle(root.targetScreen, "volume", root.anchorFor(volumeItem))
                        }
                    }

                    // The network item carries its connection's name, not
                    // just an icon -- partly because it's the one reading
                    // here you can't guess from a glyph, and partly for the
                    // fit: the two wings are equalised to the wider one, so
                    // an icons-only left wing would leave ~45px of dead
                    // space at the capsule's left end to match the date on
                    // the right. A label that's always present (the SSID,
                    // "offline" when there's nothing) balances the two by
                    // carrying information rather than padding. It's elided
                    // at 96px so a long SSID can't unbalance it the other
                    // way.
                    Item {
                        id: networkItem
                        width: networkRow.implicitWidth
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: networkRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                // nf-md-wifi / nf-md-ethernet / nf-md-wifi_off
                                text: Services.NetworkService.connectionType === "wifi" ? "\u{F05A9}"
                                    : Services.NetworkService.connectionType === "ethernet" ? "\u{F0200}"
                                    : "\u{F05AA}"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: DockState.isActive(root.targetScreen, "network") || root.highlight === "network" ? Colors.accent
                                    : Services.NetworkService.vpnConnected ? Colors.good
                                    : Services.NetworkService.connectionType === "disconnected" ? Colors.bad
                                    : Colors.icon
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.NetworkService.connectionType === "disconnected" ? "offline"
                                    : (Services.NetworkService.connectionName || Services.NetworkService.connectionType)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                width: Math.min(implicitWidth, 96)
                                elide: Text.ElideRight
                                color: root.highlight === "network" ? Colors.accent
                                    : Services.NetworkService.connectionType === "disconnected" ? Colors.bad
                                    : Colors.textDim
                            }
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
                            text: !Services.BluetoothService.powered ? "\u{F00B2}"
                                : Services.BluetoothService.connectedDevices.length > 0 ? "\u{F00B1}"
                                : "\u{F00AF}"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: DockState.isActive(root.targetScreen, "bluetooth") || root.highlight === "bluetooth" ? Colors.accent
                                : !Services.BluetoothService.powered ? Colors.muted
                                : Services.BluetoothService.connectedDevices.length > 0 ? Colors.good
                                : Colors.icon
                        }
                        TapHandler {
                            onTapped: DockState.toggle(root.targetScreen, "bluetooth", root.anchorFor(bluetoothItem))
                        }
                    }
                }
            }

            // ---- centre: the part that never moves ----
            Row {
                id: centreGroup
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.now, "hh:mm")
                    color: Colors.text
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: root.workspaceIds

                        delegate: Item {
                            readonly property bool isActive: modelData === root.activeWorkspaceId
                            readonly property bool isOccupied: root.occupiedIds.includes(modelData)

                            width: isActive ? 16 : 6
                            height: capsule.height

                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 6
                                radius: 3
                                color: parent.isActive ? Colors.accent
                                    : parent.isOccupied ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                                    : Colors.muted
                            }

                            TapHandler {
                                onTapped: Hyprland.dispatch("workspace " + modelData)
                            }
                        }
                    }
                }
            }

            // ---- right wing: battery, notifications, date ----
            Item {
                id: rightWing
                width: root.expanded ? capsule.wingWidth : 0
                height: capsule.height
                clip: true
                opacity: root.expanded ? 1 : 0

                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Row {
                    id: rightContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    // Hidden outright on a machine with no battery -- this
                    // same shell runs on the desktop's monitors too. A Row
                    // skips invisible children, and wingWidth is measured
                    // from the row, so the capsule simply comes out
                    // narrower there rather than carrying a gap.
                    Row {
                        id: batteryItem
                        spacing: 6
                        visible: Services.BatteryService.available
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            // nf-md-battery_* / nf-md-battery_charging_*. Material
                            // Design's ramps aren't evenly spaced -- the discharging
                            // set has every tenth, the charging set skips 10/50/70 --
                            // so each threshold maps to the nearest glyph that exists
                            // rather than a computed decile.
                            text: {
                                const p = Services.BatteryService.percent;
                                if (Services.BatteryService.charging) {
                                    if (p >= 95) return "\u{F0085}";
                                    if (p >= 90) return "\u{F008B}";
                                    if (p >= 80) return "\u{F008A}";
                                    if (p >= 60) return "\u{F0089}";
                                    if (p >= 40) return "\u{F0088}";
                                    if (p >= 30) return "\u{F0087}";
                                    if (p >= 20) return "\u{F0086}";
                                    return "\u{F0084}";
                                }
                                if (p >= 95) return "\u{F0079}";
                                if (p >= 90) return "\u{F0082}";
                                if (p >= 80) return "\u{F0081}";
                                if (p >= 70) return "\u{F0080}";
                                if (p >= 60) return "\u{F007F}";
                                if (p >= 50) return "\u{F007E}";
                                if (p >= 40) return "\u{F007D}";
                                if (p >= 30) return "\u{F007C}";
                                if (p >= 20) return "\u{F007B}";
                                if (p >= 10) return "\u{F007A}";
                                return "\u{F008E}";
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: Services.BatteryService.low ? Colors.bad
                                : root.highlight === "battery" ? Colors.accent
                                : Services.BatteryService.charging ? Colors.good
                                : Colors.icon
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.BatteryService.percent + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Services.BatteryService.low ? Colors.bad : Colors.textDim
                        }
                    }

                    Item {
                        id: bellItem
                        width: 20; height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            // nf-md-bell_off while DND is on, nf-md-bell otherwise
                            text: Services.NotificationService.doNotDisturb ? "\u{F009B}" : "\u{F009A}"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: DockState.isActive(root.targetScreen, "notifications") || root.highlight === "notifications" ? Colors.accent
                                : Services.NotificationService.doNotDisturb ? Colors.muted
                                : Colors.icon
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

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.now, "ddd d MMM")
                        color: Colors.textDim
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }

    }

    // The only consumers of clock.now render "hh:mm" and "ddd d MMM" --
    // neither changes more than once a minute, so a 1000 ms repeat would
    // wake the shell 60x more often than the display could differ. Fire
    // once at the next minute boundary, then re-arm: `repeat: false` plus a
    // recomputed interval keeps it aligned to :00 rather than drifting by
    // however long the shell took to start.
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
