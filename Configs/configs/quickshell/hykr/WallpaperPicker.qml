// Wallpaper picker (Super+Shift+W), replacing the separate
// quickshell/wallpaper-picker config and hypr/wallpaper.sh's rofi/wofi menu.
//
// Two modes:
// - Plain (Super+Shift+W): everything under ~/wallpapers, recursively.
//   Applying runs hypr/apply_wallpaper.sh -- awww plus the pywal colour
//   pipeline, exactly as before.
// - For a theme (forTheme(id), used by the theme picker and by apply-theme.sh
//   for a theme whose colours come from its wallpaper): that theme's own
//   wallpapers/ folder. Applying runs apply-theme.sh <theme> <wallpaper>.
//
// Type to filter by name or folder; arrows move, Enter (or a double-click)
// applies, Escape closes. Selecting never applies on its own, so arrow-key
// drift can't repaint the desktop before you meant it to.
import Quickshell
import Quickshell.Io
import QtQuick

OverlayWindow {
    id: root

    surfaceName: "hykr-wallpaper"
    cardWidth: 1180
    cardHeight: 740

    property string themeId: ""
    property string themeName: ""
    property var items: []
    property var pending: []
    property var thumbs: ({})
    property var pendingThumbs: ({})
    property string query: ""
    property bool loading: false

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/hykr/thumbs"
    readonly property string listDir: root.themeId.length > 0
        ? root.home + "/.config/theme-switcher/themes/" + root.themeId + "/wallpapers"
        : root.home + "/wallpapers"
    readonly property var results: root.filter(root.items, root.query)

    // Open in plain mode, or for a theme.
    function show(theme, name) {
        root.themeId = theme || "";
        root.themeName = name || theme || "";
        if (root.open)
            root.reload();
        root.open = true;
    }

    onOpened: {
        search.text = "";
        root.query = "";
        grid.selected = 0;
        search.focusInput();
        root.reload();
    }

    function reload() {
        root.items = [];
        root.pending = [];
        root.thumbs = {};
        root.pendingThumbs = {};
        root.loading = true;
        listProc.running = false;
        thumbProc.running = false;
        listProc.command = ["sh", "-c", root.findCommand, "sh", root.listDir];
        listProc.running = true;
    }

    // Images under $1, sorted, minus pywallpaper.jpg (apply_wallpaper.sh's
    // copy of the last pick, not a wallpaper of its own).
    readonly property string findCommand:
        "find -L \"$1\" -type f ! -name pywallpaper.jpg \\( -iname '*.jpg' -o -iname '*.jpeg'"
        + " -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | LC_ALL=C sort -f"

    function filter(list, rawQuery) {
        const q = String(rawQuery || "").trim().toLowerCase();
        if (q.length === 0)
            return list;
        return list.filter(i => (i.title + " " + i.subtitle).toLowerCase().indexOf(q) >= 0);
    }

    function entry(path) {
        const rel = path.startsWith(root.listDir + "/") ? path.slice(root.listDir.length + 1) : path;
        const slash = rel.lastIndexOf("/");
        const file = slash >= 0 ? rel.slice(slash + 1) : rel;
        const dot = file.lastIndexOf(".");
        return {
            path: path,
            title: (dot > 0 ? file.slice(0, dot) : file).replace(/[_-]+/g, " "),
            subtitle: slash >= 0 ? rel.slice(0, slash) : "",
            badge: ""
        };
    }

    function apply(item) {
        if (!item)
            return;
        if (root.themeId.length > 0)
            Quickshell.execDetached([root.home + "/.config/theme-switcher/apply-theme.sh", root.themeId, item.path]);
        else
            Quickshell.execDetached([root.home + "/.config/hypr/apply_wallpaper.sh", item.path]);
        root.open = false;
    }

    function move(delta) {
        if (root.results.length === 0)
            return;
        grid.selected = Math.max(0, Math.min(root.results.length - 1, grid.selected + delta));
        grid.keepVisible();
    }

    Process {
        id: listProc
        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    root.pending.push(root.entry(data));
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.items = root.pending;
            root.pending = [];
            root.loading = false;
            if (root.items.length > 0) {
                thumbProc.command = ["sh", "-c", root.findCommand + " | bash \"$2\" \"$3\"",
                    "sh", root.listDir, Quickshell.shellPath("thumbs.sh"), root.thumbDir];
                thumbProc.running = true;
            }
        }
    }

    // "<path>\t<thumbnail or empty>" per image, as each becomes ready.
    // Collected and published in batches: re-assigning `thumbs` for every
    // line would re-evaluate every visible card hundreds of times.
    Process {
        id: thumbProc
        stdout: SplitParser {
            onRead: data => {
                const tab = data.indexOf("\t");
                if (tab > 0) {
                    root.pendingThumbs[data.slice(0, tab)] = data.slice(tab + 1);
                    flush.start();
                }
            }
        }
        onExited: (exitCode, exitStatus) => flush.triggered()
    }

    Timer {
        id: flush
        interval: 150
        onTriggered: {
            if (Object.keys(root.pendingThumbs).length === 0)
                return;
            root.thumbs = Object.assign({}, root.thumbs, root.pendingThumbs);
            root.pendingThumbs = {};
        }
    }

    // ---------------- layout ----------------
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Row {
            width: parent.width
            spacing: 12

            SearchField {
                id: search
                width: parent.width - counter.width - parent.spacing
                placeholder: root.themeId.length > 0
                    ? "Wallpaper for " + root.themeName + "  ·  Enter applies"
                    : "Search wallpapers  ·  Enter applies, double-click works too"
                glyph: "\u{F02E9}"
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

            Text {
                id: counter
                anchors.verticalCenter: search.verticalCenter
                text: root.loading ? "Loading…" : (root.results.length + " / " + root.items.length)
                color: Theme.textFaint
                font.family: Theme.font
                font.pixelSize: Theme.fontSmall
            }
        }

        ThumbGrid {
            id: grid
            width: parent.width
            height: parent.height - search.height - parent.spacing
            columns: 4
            model: root.results
            thumbs: root.thumbs
            onActivated: index => root.apply(root.results[index])

            Text {
                anchors.centerIn: parent
                visible: !root.loading && root.results.length === 0
                text: root.items.length === 0 ? ("No wallpapers in " + root.listDir) : "No matches"
                color: Theme.textFaint
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
