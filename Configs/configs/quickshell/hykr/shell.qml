// HyKr's desktop shell (`quickshell -c hykr`): everything that isn't the bar.
// Always running -- start_bar.sh starts it next to the theme's bar -- so its
// surfaces open instantly over IPC instead of paying a Quickshell start-up
// each time:
//
//   quickshell -c hykr ipc call launcher toggle     (Super+Tab)
//   quickshell -c hykr ipc call clipboard toggle    (Super+V)
//   quickshell -c hykr ipc call wallpaper toggle    (Super+Shift+W)
//   quickshell -c hykr ipc call wallpaper forTheme <id>
//   quickshell -c hykr ipc call themes toggle       (Super+Shift+T)
//   quickshell -c hykr ipc call control toggle      (Super+M, Super+S)
//   quickshell -c hykr ipc call audio toggle        (the bars' volume icon)
//   quickshell -c hykr ipc call bluetooth toggle    (the bars' Bluetooth icon)
//   quickshell -c hykr ipc call network toggle      (the bars' network icon)
//   quickshell -c hykr ipc call osd show <volume|mic|brightness> <0-100> <muted>
//                                                   (hypr/osd.sh, the volume
//                                                   and brightness keys)
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
        themes.open = which === "themes";
        control.open = which === "control";
        audio.open = which === "audio";
        bluetooth.open = which === "bluetooth";
        network.open = which === "network";
        if (which !== "wallpaper")
            wallpaper.open = false;
    }

    function showWallpaper(themeId, themeName) {
        root.show("wallpaper");
        wallpaper.show(themeId, themeName);
    }

    Launcher {
        id: launcher
    }

    ClipboardPicker {
        id: clipboard
    }

    WallpaperPicker {
        id: wallpaper
    }

    ThemePicker {
        id: themes
        onWallpaperWanted: (themeId, themeName) => root.showWallpaper(themeId, themeName)
    }

    Osd {
        id: osd
    }

    // Quick panels. Opened from the control centre they show a back arrow
    // to it; opened from the bar they don't.
    AudioPanel {
        id: audio
        onBack: root.show("control")
    }

    BluetoothPanel {
        id: bluetooth
        onBack: root.show("control")
    }

    NetworkPanel {
        id: network
        onBack: root.show("control")
    }

    function showPanel(panel, which, fromControl) {
        panel.showBack = fromControl;
        root.show(which);
    }

    ControlCentre {
        id: control
        onThemesWanted: root.show("themes")
        onWallpaperWanted: root.showWallpaper("", "")
        onAudioWanted: root.showPanel(audio, "audio", true)
        onBluetoothWanted: root.showPanel(bluetooth, "bluetooth", true)
        onNetworkWanted: root.showPanel(network, "network", true)
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
        target: "wallpaper"
        function toggle(): void { if (wallpaper.open) wallpaper.open = false; else root.showWallpaper("", ""); }
        function open(): void { root.showWallpaper("", ""); }
        function close(): void { wallpaper.open = false; }
        // Pick a wallpaper for a theme whose colours come from one (apply-theme.sh
        // calls this when such a theme is applied without a wallpaper).
        function forTheme(theme: string): void { root.showWallpaper(theme, theme); }
    }

    IpcHandler {
        target: "themes"
        function toggle(): void { root.show(themes.open ? "" : "themes"); }
        function open(): void { root.show("themes"); }
        function close(): void { themes.open = false; }
    }

    IpcHandler {
        target: "osd"
        function show(kind: string, value: int, muted: bool): void { osd.show(kind, value, muted); }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { if (audio.open) audio.open = false; else root.showPanel(audio, "audio", false); }
        function open(): void { root.showPanel(audio, "audio", false); }
        function close(): void { audio.open = false; }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { if (bluetooth.open) bluetooth.open = false; else root.showPanel(bluetooth, "bluetooth", false); }
        function open(): void { root.showPanel(bluetooth, "bluetooth", false); }
        function close(): void { bluetooth.open = false; }
    }

    IpcHandler {
        target: "network"
        function toggle(): void { if (network.open) network.open = false; else root.showPanel(network, "network", false); }
        function open(): void { root.showPanel(network, "network", false); }
        function close(): void { network.open = false; }
    }

    IpcHandler {
        target: "control"
        function toggle(): void { root.show(control.open ? "" : "control"); }
        function open(): void { root.show("control"); }
        function close(): void { control.open = false; }
    }
}
