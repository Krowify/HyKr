// Horizontal top dock bar -- moved from the original vertical "Dock
// Rail" mockup per request, thinned down, and given the same opacity
// Hyprland's own window_rule applies to focused windows (0.9) so it
// reads as part of the same translucent-window look rather than a
// solid, un-transparent strip.
//
// Layout, left to right: workspaces / (centered) clock / battery,
// volume, network, bluetooth, date, notifications.
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

    // The bar's own height comes from Colors.qml; the layer surface is that
    // plus the gap a rounded (floating) bar keeps from the top edge -- zero
    // for the flat bar, so its surface is exactly the 34px it always was.
    readonly property int barHeight: Colors.barHeight

    screen: targetScreen
    color: "transparent"
    implicitHeight: Colors.barBottom
    exclusiveZone: Colors.barBottom

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
    //
    // Inset by Colors.barGap and rounded by Colors.barRadius when the theme asks for
    // a floating bar (Default); both are 0 for the flat one (Sakura). The
    // strip around a floating bar is fully transparent, which the theme's
    // ignore_alpha = 0.2 layer rule keeps out of the blur -- only the
    // rounded shape itself gets blurred.
    Rectangle {
        id: barBackground
        anchors.fill: parent
        anchors.topMargin: Colors.barGap
        anchors.leftMargin: Colors.barGap
        anchors.rightMargin: Colors.barGap
        radius: Colors.barRadius
        color: Colors.barBg // the theme's background at 55% alpha -- see Colors.qml
        border.width: 1
        border.color: Colors.barBorder
        // Still laid out in islands mode -- the content below is positioned
        // against it -- just not painted.
        visible: !root.islands
    }

    // ---- islands layout (Colors.barIslands -- the Default theme) ----
    //
    // Three islands instead of one bar. The content rows below are NOT
    // moved: they stay exactly where the single bar puts them (14px in from
    // its ends), and the islands are drawn around them. So the right-hand
    // icons sit at the same distance from the screen edge in both layouts
    // and shell.qml's per-icon panel offsets stay right.
    //
    // The two side islands are always the same width -- the wider of the
    // two rows, plus padding -- so the bar reads as balanced around the
    // clock however much is in each.
    readonly property bool islands: Colors.barIslands
    readonly property int islandPad: 14
    // Minimum clear space between a side island and the centre one.
    readonly property int islandSpacing: 10

    readonly property real centreWidth: clockText.implicitWidth + 32
    // Room for each side island before it would touch the centre one.
    readonly property real sideRoom: (root.width - root.centreWidth) / 2 - Colors.barGap - root.islandSpacing

    // CPU/RAM join the left island only when, at the even width they'd
    // force, BOTH side islands still clear the centre one -- computed from
    // the pieces' own widths (not leftGroup's, which depends on this) so the
    // check can't feed back into itself. On a narrow screen they're simply
    // left out rather than clipped. Per screen: each monitor's bar decides
    // for itself.
    readonly property bool showStats: root.islands
        && Math.max(workspaceRow.implicitWidth + leftGroup.spacing + statsRow.implicitWidth,
                    rightGroup.implicitWidth) + root.islandPad * 2 <= root.sideRoom

    readonly property real sideWidth: Math.max(leftGroup.implicitWidth, rightGroup.implicitWidth) + root.islandPad * 2

    component Island: Rectangle {
        y: Colors.barGap
        height: Colors.barHeight
        radius: Colors.barRadius
        color: Colors.barBg
        border.width: 1
        border.color: Colors.barBorder
    }

    // `visible` is set here, not in the component: an inline component
    // can't see this file's ids, so `root.islands` inside it would be an
    // unresolved name.
    Island {
        visible: root.islands
        x: Colors.barGap
        width: root.sideWidth
    }

    Island {
        visible: root.islands
        x: (root.width - width) / 2
        width: root.centreWidth
    }

    Island {
        visible: root.islands
        x: root.width - Colors.barGap - width
        width: root.sideWidth
    }

    // Content tracks the background exactly, so a floating bar's icons stay
    // inside its rounded outline rather than lining up with the screen.
    Item {
        anchors.fill: barBackground

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 18

            // ---- left: workspaces, then CPU/RAM when they fit ----
            Row {
                id: leftGroup
                Layout.alignment: Qt.AlignVCenter
                spacing: 16

                Row {
                    id: workspaceRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Repeater {
                        model: root.workspaceIds
                        delegate: Rectangle {
                            readonly property bool isActive: modelData === root.activeWorkspaceId
                            width: isActive ? 18 : 6
                            height: isActive ? 8 : 6
                            radius: isActive ? 4 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            // Colors.accent tracks the wallpaper -- regenerated by
                            // apply-theme.sh on a theme switch and by
                            // apply_wallpaper.sh on a wallpaper pick, same as kitty
                            // and starship. See Colors.qml. The inactive pips stay
                            // a neutral white alpha: they read as "unlit", and
                            // tinting them too would leave nothing for the active
                            // one to contrast against.
                            color: isActive ? Colors.accent : Colors.muted

                            Behavior on width { NumberAnimation { duration: 120 } }

                            TapHandler {
                                onTapped: Hyprland.dispatch("workspace " + modelData)
                            }
                        }
                    }
                }

                // CPU / RAM utilisation. Islands layout only, and only when it
                // fits -- see showStats above.
                Row {
                    id: statsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    visible: root.showStats

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CPU " + (Services.SystemStatsService.cpu >= 0 ? Services.SystemStatsService.cpu + "%" : "\u2026")
                        color: Colors.textSoft
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "RAM " + (Services.SystemStatsService.memory >= 0 ? Services.SystemStatsService.memory + "%" : "\u2026")
                        color: Colors.textSoft
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ---- right: battery, volume, network, bluetooth, date, notifications ----
            Row {
                id: rightGroup
                Layout.alignment: Qt.AlignVCenter
                spacing: 16

                // Battery sits at the head of this group -- i.e. immediately
                // left of the Wi-Fi and bluetooth icons -- and disappears
                // entirely on a machine with no battery, since this same
                // shell config also runs on the desktop's three monitors.
                // A Row skips invisible children, so nothing else shifts.
                //
                // Hovering it slides out the exact percentage. Inline rather
                // than a floating tooltip window on purpose: this bar's layer
                // surface is only barHeight (34px) tall, so anything drawn
                // below the icon would be clipped off, and an extra
                // PanelWindow is the very pattern shell.qml's header warns
                // about.
                Item {
                    id: batteryItem
                    width: batteryRow.implicitWidth
                    height: 20
                    visible: Services.BatteryService.available

                    HoverHandler { id: batteryHover }

                    Row {
                        id: batteryRow
                        spacing: batteryHover.hovered ? 5 : 0

                        Behavior on spacing { NumberAnimation { duration: 120 } }

                        // Deliberately BEFORE the glyph. The whole group is
                        // pushed right by the RowLayout's filler, so it grows
                        // leftwards into empty bar: with the label first, the
                        // battery glyph itself never moves as the label
                        // appears. After the glyph it would slide the icon out
                        // from under the pointer, dropping the hover and
                        // flickering the label on and off. Either way nothing
                        // to the right (volume, network, bluetooth, date,
                        // bell) shifts by a pixel, so the popup panels'
                        // rightOffset values stay correct.
                        Text {
                            id: batteryPercent
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.BatteryService.percent + "%"
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Services.BatteryService.low ? Colors.red : Colors.textSoft
                            // Animating width rather than toggling visible
                            // slides the label out from behind the icon, and
                            // clip keeps the digits inside whatever width it
                            // currently has. implicitWidth is pure text
                            // metrics, so this can't feed back into itself.
                            width: batteryHover.hovered ? implicitWidth : 0
                            clip: true
                            opacity: batteryHover.hovered ? 1 : 0

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Item {
                            width: 20
                            height: 20

                            Text {
                                anchors.centerIn: parent
                                // nf-md-battery_* and nf-md-battery_charging_*.
                                // Material Design's battery ramps are not
                                // evenly spaced -- the discharging set has
                                // every tenth, the charging set skips
                                // 10/50/70 -- so each threshold below maps to
                                // the nearest glyph that actually exists
                                // rather than a computed decile.
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
                                    if (p >= 90) return "\u{F0082}"; // battery_90
                                    if (p >= 80) return "\u{F0081}"; // battery_80
                                    if (p >= 70) return "\u{F0080}"; // battery_70
                                    if (p >= 60) return "\u{F007F}"; // battery_60
                                    if (p >= 50) return "\u{F007E}"; // battery_50
                                    if (p >= 40) return "\u{F007D}"; // battery_40
                                    if (p >= 30) return "\u{F007C}"; // battery_30
                                    if (p >= 20) return "\u{F007B}"; // battery_20
                                    if (p >= 10) return "\u{F007A}"; // battery_10
                                    return "\u{F008E}"; // battery_outline (empty)
                                }
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                // Same accent the other icons use for "needs
                                // your attention", here meaning on battery and
                                // under 15%.
                                color: Services.BatteryService.low ? Colors.red : Colors.icon
                            }
                        }
                    }
                }

                Item {
                    width: 20; height: 20
                    Text {
                        anchors.centerIn: parent
                        // nf-md-volume_high / nf-md-volume_mute
                        text: Services.AudioService.muted ? "\u{F075F}" : "\u{F057E}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: DockState.isActive(root.targetScreen, "volume") ? Colors.accent : Colors.icon
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
                        color: DockState.isActive(root.targetScreen, "network") ? Colors.accent : Colors.icon
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
                        color: DockState.isActive(root.targetScreen, "bluetooth") ? Colors.accent
                            : (Services.BluetoothService.powered ? Colors.icon : Colors.muted)
                    }
                    TapHandler { onTapped: DockState.toggle(root.targetScreen, "bluetooth") }
                }

                // Colors.dateSize (12 unless the theme bumps it), and the
                // theme's Nerd Font rather than "monospace" -- the same soft,
                // pixelated rendering the clock had at 12px.
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.now, "ddd d")
                    color: Colors.textSoft
                    font.pixelSize: Colors.dateSize
                    font.family: "JetBrainsMono Nerd Font"
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
                        color: DockState.isActive(root.targetScreen, "notifications") ? Colors.accent : Colors.icon
                    }
                    Rectangle {
                        visible: Services.NotificationService.unreadCount > 0
                        width: 6; height: 6; radius: 3
                        color: Colors.red
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
        //
        // The theme's Nerd Font rather than the generic "monospace" alias,
        // and Colors.clockSize (12 unless the theme bumps it): "monospace" at
        // 12px resolved to a face that rendered visibly soft/pixelated.
        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.now, "hh:mm")
            color: Colors.text
            font.pixelSize: Colors.clockSize
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Colors.clockSize > 12 ? Font.DemiBold : Font.Normal
        }
    }

    // The only consumers of clock.now render "hh:mm" and "ddd d" -- neither
    // changes more than once a minute, so a 1000 ms repeat was waking the
    // shell (and repainting) 60x more often than the display could possibly
    // differ. That is exactly the sort of idle wakeup that costs battery on
    // the machine this theme exists for. Instead: fire once, at the next
    // minute boundary, then re-arm for the following one. `repeat: false`
    // plus a recomputed interval keeps it aligned to :00 seconds rather
    // than drifting by however long the shell took to start.
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
