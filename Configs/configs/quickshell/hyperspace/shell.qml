// Entry point for `quickshell -c hyperspace`. Replaces waybar+swaync for
// the "Hyperspace" theme (its theme.json sets "bar": "quickshell-dock" and
// "quickshell": { "config": "hyperspace" }, which apply-theme.sh,
// hypr/start_bar.sh and hypr/dock_ipc.sh all read) with one Quickshell
// shell: the three-island top bar per screen, plus a native notification
// daemon and toast stack shared across all of them.
//
// The four popup panels (Volume/Network/Bluetooth/NotificationCenter) live
// here as top-level siblings, NOT nested inside DockBar.qml. They used to
// be DockBar's children in the Laptop shell this grew out of; on real
// hardware that produced intermittent "X is not a type" errors, always
// hitting whichever panel was declared last -- nesting several PanelWindows
// inside another PanelWindow's object tree isn't something Quickshell
// handles reliably. Every other Quickshell shell examined
// (mystiafin/shell's own shell.qml) only ever declares PanelWindows as
// direct children of ShellRoot. DockBar just flips shared state
// (DockState.qml) on click, handing over where the tapped icon sits;
// whichever panel is active reads that here to decide its own visibility,
// which screen to anchor to, and where along that screen to hang.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "./panels"
import "./services" as Services

ShellRoot {
    id: root

    // A panel opened from a keybind should land on the monitor you're
    // actually looking at rather than always the first one. Indexed loop
    // instead of Array.find so this only relies on the .length/[i] access
    // DockState.qml already uses on Quickshell.screens. Falls back to
    // whatever DockState points at if Hyprland reports no focused monitor,
    // or its name doesn't match any screen.
    function focusedScreen() {
        const monitor = Hyprland.focusedMonitor;
        if (monitor) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === monitor.name)
                    return Quickshell.screens[i];
            }
        }
        return DockState.activeScreen;
    }

    // Lets Hyprland keybinds and quick_settings.sh reach this shell the same
    // way they reach swaync under the waybar themes. Both call sites go
    // through hypr/dock_ipc.sh, which resolves the ACTIVE theme's quickshell
    // config name (so the same keybind reaches `-c laptop` or `-c
    // hyperspace` as appropriate) and falls back to swaync-client when no
    // such shell is running. The target name stays "dock", identical to the
    // Laptop shell's, so that script needs no per-theme special-casing.
    IpcHandler {
        target: "dock"

        // Super+N.
        function toggleNotifications(): void {
            DockState.toggle(root.focusedScreen(), "notifications");
        }

        // The quick-settings menu's "Toggle DND" entry. This is the exact
        // property NotificationCenterPanel's DND switch flips, so the two
        // stay in sync either way you toggle it.
        function toggleDnd(): void {
            Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb;
        }
    }

    Variants {
        model: Quickshell.screens
        DockBar {}
    }

    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }

    // Unlike the Laptop shell, none of these carry a hardcoded per-icon
    // offset: each reads DockState.anchorFromRight (set by DockBar at tap
    // time from the right island's live layout) and centres itself under
    // whichever icon was actually clicked.
    //
    // `colors`/`dock` hand the two root-level singletons down explicitly:
    // the panels live in panels/, a directory of their own, and reach
    // everything outside it through an explicit import (as they already do
    // for ../services) rather than assuming a root singleton resolves
    // unqualified from a subdirectory. This file sits next to both, so it
    // can just name them.
    VolumePanel {
        colors: Colors
        dock: DockState
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "volume"
    }
    NetworkPanel {
        colors: Colors
        dock: DockState
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "network"
    }
    BluetoothPanel {
        colors: Colors
        dock: DockState
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "bluetooth"
    }
    NotificationCenterPanel {
        colors: Colors
        dock: DockState
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "notifications"
    }
}
