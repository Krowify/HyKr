// Entry point for `quickshell -c laptop`. Replaces waybar+swaync for
// the "Laptop" theme (theme.json sets "bar": "quickshell-dock", which
// apply-theme.sh reads to decide which pair of processes to run) with
// one Quickshell shell: a horizontal dock bar per screen, plus a native
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
// Sourced from HyKr's own quickshell conventions (wallpaper-picker,
// hykr) for the multi-monitor Variants pattern, and mystiafin/shell for
// the native NotificationServer approach -- see
// services/NotificationService.qml.
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

    // Lets Hyprland keybinds and quick_settings.sh reach this shell the
    // same way they reach swaync under every other theme. Both call sites
    // try `quickshell -c laptop ipc call dock ...` first and fall back to
    // swaync-client, which keeps this scoped to the Laptop theme by
    // construction: no laptop shell is running under the waybar themes, so
    // the ipc call just fails there and the old swaync path runs unchanged.
    IpcHandler {
        target: "dock"

        // Super+N. Was bound to `swaync-client -t -sw`, which does nothing
        // under this theme -- swaync isn't running, the dock's own
        // notification center replaces it.
        function toggleNotifications(): void {
            DockState.toggle(root.focusedScreen(), "notifications");
        }

        // The quick-settings menu's "Toggle DND" entry, same story: it
        // shelled out to `swaync-client --toggle-dnd` and was dead here.
        // This is the exact property NotificationCenterPanel's DND switch
        // flips, so the two stay in sync either way you toggle it.
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

    VolumePanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "volume"
        rightOffset: 170
    }
    NetworkPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "network"
        rightOffset: 130
    }
    BluetoothPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "bluetooth"
        rightOffset: 90
    }
    NotificationCenterPanel {
        anchorScreen: DockState.activeScreen
        visible: DockState.activePanel === "notifications"
    }
}
