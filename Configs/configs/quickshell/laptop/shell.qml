// Entry point for `quickshell -c laptop`, the bar for the Sakura and
// Default themes (theme.json's "quickshell": { "config": "laptop" }, the
// default when a theme names none): a horizontal dock bar per screen, plus a native
// notification daemon and toast stack shared across all of them.
//
// The four popup panels (Volume/Network/Bluetooth/NotificationCenter)
// live here as top-level siblings, NOT nested inside DockBar.qml. They
// used to be DockBar's children; on real hardware that produced
// intermittent "X is not a type" errors, always hitting whichever
// panel was declared last (Bluetooth, then NotificationCenter, back to
// Bluetooth after an unrelated content rewrite ruled out the file
// content itself) -- nesting several PanelWindows inside another
// PanelWindow's object tree isn't something Quickshell handles
// reliably. Every other Quickshell shell examined (mystiafin/shell's
// own shell.qml) only ever declares PanelWindows as direct children of
// ShellRoot, never nested inside one another -- this now matches that.
// DockBar just flips shared state (DockState.qml) on click; whichever
// panel is active reads it here to decide its own visibility and which
// screen to anchor to.
//
// The panel files sit in this config's root, not in a panels/
// subdirectory: an unqualified `import "./panels"` made exactly one panel
// per launch fail with "<Panel> is not a type" -- a different one each
// time -- and took the whole shell down with it. Same failure, same fix
// as ../bar/ (see its README, "Why every .qml except the services sits in
// the config root"). services/ stays a subdirectory because it is imported
// qualified (`as Services`) and has never failed.
//
// Sourced from HyKr's own quickshell conventions (wallpaper-picker,
// hykr) for the multi-monitor Variants pattern, and mystiafin/shell for
// the native NotificationServer approach -- see
// services/NotificationService.qml.
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

    // Lets Hyprland keybinds and quick_settings.sh reach this shell. Both
    // call sites go through hypr/dock_ipc.sh, which resolves the ACTIVE
    // theme's quickshell config name; the target name "dock" is shared with
    // the bar shell's, so that script needs no per-theme special-casing.
    IpcHandler {
        target: "dock"

        // Super+N: the dock's own notification center.
        function toggleNotifications(): void {
            DockState.toggle(root.focusedScreen(), "notifications");
        }

        // The quick-settings menu's "Toggle DND" entry. This is the exact
        // property NotificationCenterPanel's DND switch
        // flips, so the two stay in sync either way you toggle it.
        function toggleDnd(): void {
            Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb;
        }
    }

    Variants {
        model: Quickshell.screens
        DockBar {}
    }

    // CPU/RAM polling exists for the islands layout's left island alone
    // (the Default theme); Sakura's flat bar leaves it switched off.
    Binding {
        target: Services.SystemStatsService
        property: "wanted"
        value: Colors.barIslands
    }

    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }

    // barHeight / rightOffset follow Colors.qml: a floating bar sits
    // Colors.barTopGap lower and Colors.barGap further in from the right edge
    // than the flat one, so the panels move with it. Both are 0 for the flat
    // Sakura bar, which leaves these at the values they always had.
    VolumePanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "volume"
        barHeight: Colors.barBottom
        rightOffset: 170 + Colors.barGap
    }
    NetworkPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "network"
        barHeight: Colors.barBottom
        rightOffset: 130 + Colors.barGap
    }
    BluetoothPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "bluetooth"
        barHeight: Colors.barBottom
        rightOffset: 90 + Colors.barGap
    }
    NotificationCenterPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "notifications"
        barHeight: Colors.barBottom
    }
}
