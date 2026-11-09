// The "stats" bar style: three short translucent pills tucked under the top
// edge -- system readings on the left, the clock in the centre, media and
// controls on the right. Plain foreground text, colour only where something
// wants attention (a hot CPU, a low battery).
//
// This is the waybar bar the Minimal theme used to run (ported from
// 43PR/dotfiles; theme-switcher/themes/minimal/templates/waybar/, removed
// when it moved here), redone in Quickshell with the same module order and
// labels:
//
//   left    CPU 12% | GPU 3% | RAM 41% |  52°C |  87%
//   centre  14:05            (hover: the full date, waybar's tooltip)
//   right   title - artist |  ssid |  65% | bell | ⏻
//
// Differences from the waybar version:
//   - the network and volume modules open this shell's own panels (right
//     click still reaches NetworkManager / mute, middle click pavucontrol);
//   - there's a notification bell, since this shell -- not swaync -- is the
//     notification daemon now and its history needs somewhere to live;
//   - the GPU module hides itself on a machine where no GPU load can be
//     read, rather than printing "GPU %".
//
// Hovering a module grows its text a touch, as the original's
// `font-size: 14px` on :hover did -- done with `scale` here so the pill's
// width doesn't jump around under the pointer.
//
// Like the other bars this is ONE full-width transparent layer surface with
// the pills drawn inside it, blurred through ignore_alpha = 0.2 in the
// theme's hyprland.lua.tpl. Every glyph is a \u escape -- see PillBar.qml.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
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


    function anchorFor(item) {
        const centre = item.mapToItem(null, item.width / 2, 0);
        return root.width - centre.x;
    }

    // A module's colour: the accent while its panel is open, otherwise the
    // role colour in a colourful theme, otherwise plain foreground.
    function tint(roleColour, panel) {
        if (panel !== undefined && DockState.isActive(root.targetScreen, panel))
            return Colors.accent;
        return DockState.colorful ? roleColour : Colors.text;
    }

    // ---- media ----

    // Mpris.players is a live model; .values is its array.
    readonly property var players: Mpris.players ? Mpris.players.values : []
    // The player to show: one that's playing; failing that, one paused
    // mid-track (so pausing doesn't make it vanish). A player that has
    // stopped or has nothing loaded doesn't count: browsers keep their MPRIS
    // player registered after the video's tab is closed, and falling back to
    // "whatever player exists" left that dead track on screen. Nothing
    // left -> null, and the widget goes away / resets.
    readonly property var player: {
        const ps = root.players;
        let paused = null;
        for (let i = 0; i < ps.length; i++) {
            const p = ps[i];
            if (!p)
                continue;
            if (p.isPlaying)
                return p;
            if (paused === null && p.playbackState === MprisPlaybackState.Paused && (p.trackTitle || "").length > 0)
                paused = p;
        }
        return paused;
    }
    readonly property string mediaText: {
        const p = root.player;
        if (!p)
            return "";
        const title = p.trackTitle || "";
        // trackArtist (a string) on current Quickshell, trackArtists (a
        // list) on older releases -- read whichever this build has.
        const artist = p.trackArtist !== undefined ? (p.trackArtist || "")
            : (p.trackArtists ? p.trackArtists.join(", ") : "");
        const full = title && artist ? title + " - " + artist : (title || artist);
        // waybar's max-length: 50.
        return full.length > 50 ? full.slice(0, 49) + "…" : full;
    }

    // ---- building blocks ----

    // One module: an optional Nerd Font icon, then a text label. Clicks and
    // scrolls come back out as signals so each use site says what it does in
    // one place.
    //
    // The icon is its OWN Text, never glued onto the label string. With the
    // two in one 11px string, every Nerd Font (private-use) glyph rendered
    // as nothing on a live machine -- the thermometer, battery, wifi, mute
    // and bell all vanished, leaving their labels -- while the Laptop dock
    // and the pill bar, which both draw each icon as a separate, larger
    // Text, showed the very same glyphs. This follows their pattern.
    component Chip: Item {
        id: chip

        property string icon: ""
        property string text: ""
        property color tint: Colors.text
        property bool bold: false
        property bool interactive: true

        signal leftClicked()
        signal rightClicked()
        signal middleClicked()
        signal scrolled(int direction)

        // 10px padding each side, as the original's `padding: 0 10px`.
        implicitWidth: content.implicitWidth + 20
        width: implicitWidth
        height: parent ? parent.height : 0

        Row {
            id: content
            anchors.centerIn: parent
            spacing: chip.icon.length > 0 && chip.text.length > 0 ? 6 : 0
            scale: mouse.containsMouse ? 1.2 : 1
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Text {
                visible: chip.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                color: chip.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }
            Text {
                visible: chip.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: chip.bold
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: chip.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: ev => {
                if (ev.button === Qt.RightButton)
                    chip.rightClicked();
                else if (ev.button === Qt.MiddleButton)
                    chip.middleClicked();
                else
                    chip.leftClicked();
            }
            onWheel: ev => chip.scrolled(ev.angleDelta.y > 0 ? 1 : -1)
        }
    }

    // One of the three pills.
    component Pill: Rectangle {
        default property alias content: row.data
        y: DockState.statsTopGap
        height: DockState.statsHeight
        width: row.implicitWidth + 4
        radius: 10
        color: Colors.island
        border.width: 1
        border.color: Colors.hairline

        Row {
            id: row
            anchors.centerIn: parent
            height: parent.height
        }
    }

    // ---- left: system ----
    Pill {
        id: leftPill
        x: DockState.statsMargin

        Chip {
            text: Services.SystemStatsService.cpu >= 0 ? "CPU " + Services.SystemStatsService.cpu + "%" : "CPU …"
            tint: DockState.colorful ? Colors.accent : Colors.text
            interactive: false
        }
        Chip {
            visible: Services.SystemStatsService.gpuAvailable
            text: "GPU " + Services.SystemStatsService.gpu + "%"
            tint: DockState.colorful ? Colors.accentAlt : Colors.text
            interactive: false
        }
        Chip {
            text: Services.SystemStatsService.memory >= 0 ? "RAM " + Services.SystemStatsService.memory + "%" : "RAM …"
            tint: DockState.colorful ? Colors.blue : Colors.text
            interactive: false
        }
        Chip {
            visible: Services.SystemStatsService.temperatureAvailable
            // nf-fa-thermometer_half
            icon: "\uF2C9"
            text: Services.SystemStatsService.temperature + "\u00B0C"
            // waybar's .critical class: red at 80°C and up.
            tint: Services.SystemStatsService.temperatureHigh ? Colors.bad : DockState.colorful ? Colors.orange : Colors.text
            // Same toggle the waybar module had on click.
            onLeftClicked: Quickshell.execDetached(["sh", "-c", "pkill hyprsunset || hyprsunset"])
        }
        Chip {
            visible: Services.BatteryService.available
            readonly property int p: Services.BatteryService.percent
            // nf-fa-bolt while charging, else nf-fa-battery_* by level --
            // the five icons waybar's format-icons used.
            icon: Services.BatteryService.charging ? "\uF0E7"
                : p >= 90 ? "\uF240" : p >= 65 ? "\uF241" : p >= 40 ? "\uF242" : p >= 15 ? "\uF243" : "\uF244"
            text: p + "%"
            // waybar's states: warning at 20, critical at 10.
            tint: !Services.BatteryService.plugged && p <= 10 ? Colors.bad
                : !Services.BatteryService.plugged && p <= 20 ? Colors.warn
                : DockState.colorful ? Colors.good : Colors.text
            interactive: false
        }
    }

    // ---- centre: clock ----
    Pill {
        id: centrePill
        anchors.horizontalCenter: parent.horizontalCenter

        Chip {
            id: clockChip
            // The original showed the date in a tooltip; hovering swaps it
            // into the pill instead -- no tooltip window to manage.
            text: hovered ? Qt.formatDateTime(clock.now, "ddd d MMM yyyy") + "  " + Qt.formatDateTime(clock.now, "hh:mm")
                : Qt.formatDateTime(clock.now, "hh:mm")
            readonly property bool hovered: clockHover.hovered
            bold: true
            interactive: false
            HoverHandler { id: clockHover }
        }
    }

    // ---- right: media, network, volume, notifications, power ----
    Pill {
        id: rightPill
        x: parent.width - width - DockState.statsMargin

        Chip {
            visible: root.mediaText.length > 0
            text: root.mediaText
            tint: DockState.colorful ? Colors.accent : Colors.text
            onLeftClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
            onRightClicked: if (root.player && root.player.canGoNext) root.player.next()
            onScrolled: dir => {
                if (!root.player)
                    return;
                if (dir > 0 && root.player.canGoPrevious)
                    root.player.previous();
                else if (dir < 0 && root.player.canGoNext)
                    root.player.next();
            }
        }

        Chip {
            id: networkChip
            readonly property string type: Services.NetworkService.connectionType
            readonly property string name: Services.NetworkService.connectionName
            // nf-fa-wifi / nf-md-ethernet / nf-md-wifi_off
            icon: type === "wifi" ? "\uF1EB" : type === "ethernet" ? "\u{F0200}" : "\u{F05AA}"
            text: type === "wifi" ? (name.length > 18 ? name.slice(0, 17) + "\u2026" : name)
                : type === "ethernet" ? "Wired" : "Offline"
            tint: type === "disconnected" ? Colors.bad : root.tint(Colors.good, "network")
            onLeftClicked: DockState.openQuickPanel("network")
            onRightClicked: Services.NetworkService.openNetworkManager()
        }

        Chip {
            id: volumeChip
            icon: Services.AudioService.muted ? "\u{F075F}"
                : Services.AudioService.volume < 34 ? "\uF026" : Services.AudioService.volume < 67 ? "\uF027" : "\uF028"
            text: Services.AudioService.muted ? "Muted" : Services.AudioService.volume + "%"
            tint: root.tint(Colors.orange, "volume")
            onLeftClicked: DockState.openQuickPanel("audio")
            onRightClicked: Services.AudioService.toggleMute()
            onMiddleClicked: Quickshell.execDetached(["pavucontrol"])
            onScrolled: dir => Services.AudioService.stepVolume(dir * 5)
        }

        Chip {
            id: bellChip
            // nf-md-bell / nf-md-bell_off (Do Not Disturb), plus the unread
            // count when there is one -- no room for a dot at this size.
            icon: Services.NotificationService.doNotDisturb ? "\u{F009B}" : "\u{F009A}"
            text: Services.NotificationService.unreadCount > 0 ? String(Services.NotificationService.unreadCount) : ""
            tint: Services.NotificationService.unreadCount > 0 && !DockState.isActive(root.targetScreen, "notifications")
                ? Colors.accent
                : root.tint(Colors.bad, "notifications")
            onLeftClicked: DockState.toggle(root.targetScreen, "notifications", root.anchorFor(bellChip))
            onRightClicked: Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb
        }

        Chip {
            // ⏻ -- the power-symbol codepoint itself, as the original used.
            icon: "\u23FB"
            onLeftClicked: Quickshell.execDetached(["wlogout"])
        }
    }

    // Minute-aligned clock, same as the other bars.
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
