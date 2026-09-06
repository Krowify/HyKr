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
import QtQuick
import "./panels"

ShellRoot {
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
