// Shared state between DockBar (which only needs to set/toggle it) and
// the four popup panels, now declared as top-level siblings in
// shell.qml rather than nested inside DockBar -- see shell.qml's
// header comment for why.
pragma Singleton

import Quickshell
import QtQuick

QtObject {
    id: root

    property string activePanel: "" // "" | "volume" | "network" | "bluetooth" | "notifications"
    // Defaults to a real screen rather than null -- the four panels
    // that bind to this are always-instantiated top-level PanelWindows
    // (just hidden via visible: false until something's active), and
    // PanelWindow.screen may not tolerate null before anything's ever
    // been opened.
    property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function toggle(screen, name) {
        // Closing just clears activePanel ("" matches no panel's visible
        // binding) -- activeScreen is left as-is rather than reset to
        // null, since these panels stay instantiated (only hidden) and
        // shouldn't ever see a null screen.
        if (root.activePanel === name && root.activeScreen === screen) {
            root.activePanel = "";
        } else {
            root.activePanel = name;
            root.activeScreen = screen;
        }
    }

    function isActive(screen, name) {
        return root.activePanel === name && root.activeScreen === screen;
    }
}
