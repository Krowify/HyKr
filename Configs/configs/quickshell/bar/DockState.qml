// Shared state between the bars (which only set/toggle it) and the four
// popup panels, declared as top-level siblings in shell.qml rather than
// nested inside a bar -- see shell.qml's header comment for why.
//
// It also owns the bar's geometry and the active theme's bar STYLE. The bars
// lay themselves out from these and the panels position themselves against
// them, so the two can't drift apart: change a height here and the panels
// still hang the right distance below the bar.
//
// A `Singleton` (Quickshell's, not a bare QtObject) because it holds a
// FileView child -- QtObject has no default property to put one in.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---- which bar is running ----
    //
    // Chosen by the active THEME, not edited here. apply-theme.sh writes
    // style.json in this directory from theme.json's "quickshell" block on
    // every theme apply, e.g.
    //
    //   "quickshell": { "config": "bar", "style": "pill", "colorful": true }
    //
    // and this FileView watches it, so a running shell re-lays itself out the
    // moment it changes (apply-theme.sh restarts the shell anyway, but a
    // hand edit of style.json shows up live).
    //
    //   "notch"   -> NotchBar.qml, one capsule hanging from the top edge that
    //                widens when something changes (Hyperspace)
    //   "islands" -> DockBar.qml, three floating islands across the top
    //   "pill"    -> PillBar.qml, one centred pill holding everything
    //                (Arch, Dynamic, Everforest, Graphite)
    //   "stats"   -> StatsBar.qml, three pills: system stats / clock /
    //                media + controls (Minimal)
    //
    // Anything unrecognised falls back to "notch", the style this shell
    // shipped with.
    readonly property var knownStyles: ["notch", "islands", "pill", "stats"]
    readonly property string barStyle: knownStyles.indexOf(styleFile.style) >= 0 ? styleFile.style : "notch"

    // Per-module colours in the pill/stats bars: each module gets its own
    // role colour (volume orange, network green, ...) instead of all of them
    // sharing the foreground. Arch's waybar bar looked like that, so
    // its theme.json turns it on.
    readonly property bool colorful: styleFile.colorful === true

    // How opaque the bars' own backgrounds are. Floored at 0.25: every theme's
    // hyprland.lua.tpl blurs the bar with ignore_alpha = 0.2, so anything at
    // or under that would lose its blur and float as bare text over the
    // wallpaper. Capped at 1 for obvious reasons.
    readonly property real islandAlpha: {
        const a = Number(styleFile.alpha);
        return isFinite(a) && a > 0 ? Math.max(0.25, Math.min(1, a)) : 0.55;
    }

    FileView {
        path: Quickshell.shellPath("style.json")
        // Read before the first frame: barStyle decides which bar shell.qml
        // builds, and an async read would build the default notch first and
        // then tear it down for the theme's real style a moment later.
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        // A fresh install that has never applied a theme has no style.json:
        // the adapter then just keeps the defaults below.

        JsonAdapter {
            id: styleFile
            property string style: "notch"
            property bool colorful: false
            property real alpha: 0.55
        }
    }

    // ---- geometry, read by whichever bar is running, and by every panel ----

    // Gap between the top of the screen and the top of the islands. This is
    // the whole point of the floating-island layout: the wallpaper shows
    // through above and between them. Unused by the notch, which hangs off
    // the screen edge instead.
    readonly property int topGap: 8
    readonly property int islandHeight: 30
    // Horizontal gap from the screen edge to the left/right islands -- and
    // the minimum gap the notch keeps from either edge when its content is
    // wider than the output.
    readonly property int islandMargin: 14
    // Inner padding at each end of an island's content row.
    readonly property int islandPadding: 13

    // The notch capsule's height, which is also its layer surface's height
    // and its exclusive zone: it grows sideways only, never down, so the
    // surface is a fixed strip and tiled windows never reflow when it opens.
    readonly property int notchHeight: 30

    // The pill: the same 10px drop and 34px height the waybar bar it replaces
    // had (margin-top 10, height 34), so windows sit where they always did.
    readonly property int pillTopGap: 10
    readonly property int pillHeight: 34

    // The stats bar: Minimal's thin strip -- three short pills tucked right up
    // under the top edge.
    readonly property int statsTopGap: 4
    readonly property int statsHeight: 26
    readonly property int statsMargin: 6

    // The bottom edge of whichever bar is running: the layer surface height
    // and exclusive zone, and the line every popup panel hangs below.
    readonly property int barHeight: {
        switch (root.barStyle) {
        case "islands":
            return root.topGap + root.islandHeight + 4;
        case "pill":
            return root.pillTopGap + root.pillHeight;
        case "stats":
            return root.statsTopGap + root.statsHeight + 2;
        default:
            return root.notchHeight;
        }
    }

    // ---- panel state ----

    property string activePanel: "" // "" | "volume" | "network" | "bluetooth" | "notifications"
    // Defaults to a real screen rather than null -- the four panels that bind
    // to this are always-instantiated top-level PanelWindows (just hidden via
    // visible: false until something's active), and PanelWindow.screen may not
    // tolerate null before anything's ever been opened.
    property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // Distance from the screen's right edge to the CENTRE of whichever icon
    // was last tapped. Each bar computes it live from its own layout and hands
    // it over on every toggle, so a panel lands under its icon no matter how
    // the bar's contents are sized that second -- the battery and volume
    // readouts change width as their numbers do ("9%" vs "100%"), which a
    // hardcoded per-icon offset (the Laptop dock's approach) could not track.
    // The default is a sane mid-cluster value for the very first paint,
    // before anything's been tapped.
    property real anchorFromRight: 90

    // Where a panel of the given width should sit, as a right margin, so its
    // centre lines up with that icon -- clamped so a panel near either screen
    // edge stays fully on screen instead of hanging off it.
    function panelMargin(panelWidth, screenWidth) {
        const ideal = root.anchorFromRight - panelWidth / 2;
        const maxMargin = Math.max(root.islandMargin, (screenWidth || 0) - panelWidth - root.islandMargin);
        return Math.max(root.islandMargin, Math.min(ideal, maxMargin));
    }

    function toggle(screen, name, fromRight) {
        // Closing just clears activePanel ("" matches no panel's visible
        // binding) -- activeScreen is left as-is rather than reset to null,
        // since these panels stay instantiated (only hidden) and shouldn't
        // ever see a null screen.
        if (root.activePanel === name && root.activeScreen === screen) {
            root.activePanel = "";
            return;
        }
        // Move the anchor BEFORE showing the panel, so it never paints one
        // frame under the previously tapped icon and then jumps.
        if (fromRight !== undefined)
            root.anchorFromRight = fromRight;
        root.activePanel = name;
        root.activeScreen = screen;
    }

    function isActive(screen, name) {
        return root.activePanel === name && root.activeScreen === screen;
    }
}
