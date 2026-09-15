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

    // Exactly one of these instantiates anything: Variants over an empty
    // model builds nothing, so the unselected bar costs a comparison and no
    // window. DockState.barStyle is the single switch -- see its comment.
    Variants {
        model: DockState.barStyle === "notch" ? Quickshell.screens : []
        NotchBar {}
    }

    Variants {
        model: DockState.barStyle === "notch" ? [] : Quickshell.screens
        DockBar {}
    }

    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }

    // Unlike the Laptop shell, none of these carry a hardcoded per-icon
    // offset: each reads DockState.anchorFromRight -- set by whichever bar
    // is running, at tap time, from its own live layout -- and centres
    // itself under the icon that was actually clicked. That is what lets
    // the same four panels serve both a fixed row of islands and a capsule
    // whose icons move as it opens.
    //
    // `colors`/`dock` hand the two singletons down explicitly rather than
    // each panel naming them -- see the note at the top of any panel file.
    //
    // The panels live in the config ROOT, beside this file, and not in a
    // panels/ subdirectory. They were in one, reached by an unqualified
    // `import "./panels"`, and it failed like this, at random:
    //
    //   ERROR: caused by @shell.qml[119:5]: NotificationCenterPanel is not a type
    //
    // Exactly one of the four failed per launch, a different one each time,
    // with no inner cause -- three identical runs named three different
    // panels. It survived disabling and deleting Qt's QML disk cache, and
    // moving the laptop config (which has four identically-named panels of
    // its own) out of ~/.config/quickshell entirely. Nothing in the files
    // themselves: rewriting the named file just moved the error to another.
    //
    // Everything that resolves reliably in this shell -- DockBar, NotchBar,
    // NotificationToasts, Colors, DockState -- is a file in this directory,
    // so the panels are too now. The same wandering error is documented in
    // ../laptop/shell.qml, which still has a panels/ directory; if it turns
    // up there, this is the fix.
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
