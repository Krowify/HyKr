// Shared state between DockBar (which only sets/toggles it) and the four
// popup panels, declared as top-level siblings in shell.qml rather than
// nested inside DockBar -- see shell.qml's header comment for why.
//
// It also owns the bar's geometry constants. DockBar lays the islands out
// from them and the panels position themselves against them, so the two
// can't drift apart: change islandHeight here and the panels still hang the
// right distance below the bar.
pragma Singleton

import Quickshell
import QtQuick

QtObject {
    id: root

    // ---- geometry, read by DockBar and every panel ----

    // Gap between the top of the screen and the top of the islands. This is
    // the whole point of the floating-island layout: the wallpaper shows
    // through above and between them.
    readonly property int topGap: 8
    readonly property int islandHeight: 30
    // Horizontal gap from the screen edge to the left/right islands.
    readonly property int islandMargin: 14
    // Inner padding at each end of an island's content row.
    readonly property int islandPadding: 13
    // The layer surface's height (and its exclusive zone), so tiled windows
    // start below the islands rather than under them.
    readonly property int barHeight: root.topGap + root.islandHeight + 4

    // ---- panel state ----

    property string activePanel: "" // "" | "volume" | "network" | "bluetooth" | "notifications"
    // Defaults to a real screen rather than null -- the four panels that bind
    // to this are always-instantiated top-level PanelWindows (just hidden via
    // visible: false until something's active), and PanelWindow.screen may not
    // tolerate null before anything's ever been opened.
    property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // Distance from the screen's right edge to the CENTRE of whichever icon
    // was last tapped. DockBar computes it live from the right island's own
    // layout and hands it over on every toggle, so a panel lands under its
    // icon no matter how the island's contents are sized that second -- the
    // battery readout in there changes width as the percentage does ("9%" vs
    // "100%"), which a hardcoded per-icon offset (the Laptop dock's approach)
    // could not track. The default is a sane mid-cluster value for the very
    // first paint, before anything's been tapped.
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
