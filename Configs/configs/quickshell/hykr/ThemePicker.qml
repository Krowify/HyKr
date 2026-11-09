// Theme picker (Super+Shift+T), replacing theme-picker.sh's rofi/wofi menu.
//
// One card per installed theme (themes.sh), previewed with its wallpaper, the
// active one marked. Enter or a double-click applies it with apply-theme.sh.
// A theme whose colours come from its wallpaper (dynamic_colors: Dynamic,
// Hyperspace, Sakura) opens the wallpaper picker on that theme's own
// wallpapers instead -- apply-theme.sh needs the wallpaper to generate the
// palette from.
import Quickshell
import Quickshell.Io
import QtQuick

OverlayWindow {
    id: root

    surfaceName: "hykr-themes"
    cardWidth: 1000
    cardHeight: 640

    property var items: []
    property var pending: []
    property var thumbs: ({})
    property string query: ""

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/hykr/thumbs"
    readonly property var results: root.filter(root.items, root.query)

    // A dynamic-colours theme was picked: shell.qml opens the wallpaper
    // picker for it.
    signal wallpaperWanted(string themeId, string themeName)

    onOpened: {
        search.text = "";
        root.query = "";
        root.items = [];
        root.pending = [];
        search.focusInput();
        listProc.running = false;
        listProc.running = true;
    }

    function filter(list, rawQuery) {
        const q = String(rawQuery || "").trim().toLowerCase();
        if (q.length === 0)
            return list;
        return list.filter(t => (t.title + " " + t.id).toLowerCase().indexOf(q) >= 0);
    }

    function apply(theme) {
        if (!theme)
            return;
        root.open = false;
        if (theme.dynamic)
            root.wallpaperWanted(theme.id, theme.title);
        else
            Quickshell.execDetached([root.home + "/.config/theme-switcher/apply-theme.sh", theme.id]);
    }

    function move(delta) {
        if (root.results.length === 0)
            return;
        grid.selected = Math.max(0, Math.min(root.results.length - 1, grid.selected + delta));
        grid.keepVisible();
    }

    // <id>\t<name>\t<preview>\t<dynamic>\t<active>
    Process {
        id: listProc
        command: ["bash", Quickshell.shellPath("themes.sh")]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split("\t");
                if (f.length < 5)
                    return;
                root.pending.push({
                    id: f[0],
                    title: f[1],
                    path: f[2],
                    dynamic: f[3] === "true",
                    active: f[4] === "true",
                    subtitle: f[3] === "true" ? "colours from your wallpaper" : "",
                    badge: f[4] === "true" ? "ACTIVE" : ""
                });
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.items = root.pending;
            root.pending = [];
            // Start on the active theme.
            let active = 0;
            for (let i = 0; i < root.results.length; i++) {
                if (root.results[i].active)
                    active = i;
            }
            grid.selected = active;
            grid.keepVisible();
            const previews = root.items.map(t => t.path).filter(p => p.length > 0);
            if (previews.length > 0) {
                thumbProc.command = ["bash", Quickshell.shellPath("thumbs.sh"), root.thumbDir].concat(previews);
                thumbProc.running = true;
            }
        }
    }

    Process {
        id: thumbProc
        stdout: SplitParser {
            onRead: data => {
                const tab = data.indexOf("\t");
                if (tab > 0) {
                    const next = Object.assign({}, root.thumbs);
                    next[data.slice(0, tab)] = data.slice(tab + 1);
                    root.thumbs = next;
                }
            }
        }
    }

    // ---------------- layout ----------------
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        SearchField {
            id: search
            width: parent.width
            placeholder: "Search themes  ·  Enter applies"
            glyph: "\u{F03D8}"
            gridNav: true
            rowStep: grid.columns
            onTextChanged: {
                root.query = search.text;
                grid.selected = 0;
                grid.positionViewAtBeginning();
            }
            onAccepted: root.apply(root.results[grid.selected])
            onDismissed: root.open = false
            onNavigate: delta => root.move(delta)
        }

        ThumbGrid {
            id: grid
            width: parent.width
            height: parent.height - search.height - parent.spacing
            columns: 3
            model: root.results
            thumbs: root.thumbs
            onActivated: index => root.apply(root.results[index])
        }
    }
}
