// Entry point for `quickshell -c laptop`. Replaces waybar+swaync for
// the "Laptop" theme (theme.json sets "bar": "quickshell-dock", which
// apply-theme.sh reads to decide which pair of processes to run) with
// one Quickshell shell: a vertical dock rail per screen, plus a native
// notification daemon and toast stack shared across all of them.
//
// Sourced from HyKr's own quickshell conventions (wallpaper-picker,
// hykr) for the multi-monitor Variants pattern, and mystiafin/shell for
// the native NotificationServer approach -- see
// services/NotificationService.qml.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens
        DockBar {}
    }

    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }
}
