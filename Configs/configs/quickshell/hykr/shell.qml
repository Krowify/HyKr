// HyKr's desktop shell (`quickshell -c hykr`): everything that isn't the bar.
// Always running -- start_bar.sh starts it next to the theme's bar -- so its
// surfaces open instantly over IPC instead of paying a Quickshell start-up
// each time:
//
//   quickshell -c hykr ipc call launcher toggle     (Super+Tab)
//   quickshell -c hykr ipc call clipboard toggle    (Super+V)
//   quickshell -c hykr ipc call panel toggle        (Super+M)
//
// hypr/hykr.sh wraps those calls and starts the shell first if it isn't up.
//
// It is a separate process from the bar on purpose: a QML error anywhere in a
// Quickshell config stops that whole config from loading, so keeping the
// launcher and pickers out of the bar means a bug here can never take the
// bar or notifications down with it (and vice versa).
//
// Colours come from colors.json, which apply-theme.sh and apply_wallpaper.sh
// rewrite for every quickshell/*/colors.json -- see Theme.qml. qs-stop.sh
// excludes this config by name, so a theme switch never mistakes it for a bar.
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    // Opening one surface closes the others: two keyboard-grabbing overlays
    // at once would fight over focus.
    function show(which) {
        launcher.open = which === "launcher";
        clipboard.open = which === "clipboard";
        panel.open = which === "panel";
    }

    Launcher {
        id: launcher
    }

    ClipboardPicker {
        id: clipboard
    }

    LegacyPanel {
        id: panel
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.show(launcher.open ? "" : "launcher"); }
        function open(): void { root.show("launcher"); }
        function close(): void { launcher.open = false; }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.show(clipboard.open ? "" : "clipboard"); }
        function open(): void { root.show("clipboard"); }
        function close(): void { clipboard.open = false; }
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.show(panel.open ? "" : "panel"); }
        function open(): void { root.show("panel"); }
        function close(): void { panel.open = false; }
    }
}
