// App launcher (Super+Tab), replacing `wofi --show drun`.
//
// The app list is Quickshell's own DesktopEntries -- the installed .desktop
// files, kept current as packages come and go -- so nothing external is
// involved. Type to filter, Up/Down (or Ctrl+J/K) to move, Enter to launch,
// Escape or a click outside to close.
//
// Ranking: exact name, then name prefix, then the start of any word in the
// name, then anywhere in the name, then the description / keywords. Ties go
// to whatever you launch most (counts kept in ~/.local/state/hykr/), then
// alphabetical. With an empty search, the most-launched apps come first.
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

OverlayWindow {
    id: root

    surfaceName: "hykr-launcher"
    cardWidth: 620
    cardHeight: 470

    property string query: ""
    property int selected: 0

    readonly property var apps: {
        const all = DesktopEntries.applications.values;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            if (all[i] && !all[i].noDisplay && all[i].name)
                out.push(all[i]);
        }
        return out;
    }
    readonly property var results: root.rank(root.apps, root.query, usage.counts)

    onOpened: {
        search.text = "";
        root.query = "";
        root.selected = 0;
        list.positionViewAtBeginning();
        search.focusInput();
    }

    onResultsChanged: root.selected = Math.max(0, Math.min(root.selected, root.results.length - 1))

    function score(app, q) {
        if (q.length === 0)
            return 1;
        const name = String(app.name || "").toLowerCase();
        if (name === q)
            return 100;
        if (name.startsWith(q))
            return 80;
        const words = name.split(/[\s\-_.]+/);
        for (let i = 0; i < words.length; i++) {
            if (words[i].startsWith(q))
                return 60;
        }
        if (name.indexOf(q) >= 0)
            return 40;
        const keywords = app.keywords ? Array.from(app.keywords).join(" ") : "";
        const extra = [app.genericName, app.comment, keywords, app.id].join(" ").toLowerCase();
        return extra.indexOf(q) >= 0 ? 20 : 0;
    }

    function rank(list, rawQuery, counts) {
        const q = String(rawQuery || "").trim().toLowerCase();
        const scored = [];
        for (let i = 0; i < list.length; i++) {
            const s = root.score(list[i], q);
            if (s > 0) {
                const used = counts ? (counts[list[i].id] || 0) : 0;
                scored.push({ app: list[i], score: s + Math.min(15, used) });
            }
        }
        // Case-insensitive on purpose: localeCompare alone sorts "Zed" before
        // "btop" under the C locale.
        scored.sort((a, b) => (b.score - a.score)
            || String(a.app.name).toLowerCase().localeCompare(String(b.app.name).toLowerCase()));
        return scored.slice(0, 80).map(x => x.app);
    }

    function launch(app) {
        if (!app)
            return;
        root.bump(app.id);
        // DesktopEntry.execute() ignores Terminal=true, so terminal apps (htop,
        // nvim, ...) go through kitty explicitly, as wofi's drun mode did.
        if (app.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(Array.from(app.command)));
        else
            app.execute();
        root.open = false;
    }

    function move(delta) {
        if (root.results.length === 0)
            return;
        root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta));
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    // ---------------- launch counts ----------------
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/hykr"

    function bump(id) {
        if (!id)
            return;
        const next = Object.assign({}, usage.counts);
        next[id] = (next[id] || 0) + 1;
        usage.counts = next;
        usageFile.writeAdapter();
    }

    // FileView can't create the directory it writes into.
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.stateDir])

    FileView {
        id: usageFile
        path: root.stateDir + "/launcher.json"
        printErrors: false

        JsonAdapter {
            id: usage
            property var counts: ({})
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
            placeholder: "Search apps"
            glyph: "\u{F0349}"
            onTextChanged: {
                root.query = search.text;
                root.selected = 0;
                list.positionViewAtBeginning();
            }
            onAccepted: root.launch(root.results[root.selected])
            onDismissed: root.open = false
            onNavigate: delta => root.move(delta)
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - search.height - parent.spacing
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.results
            currentIndex: root.selected

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: ListView.view.width
                height: 48
                radius: Theme.radiusSmall
                color: row.index === root.selected ? Theme.selected : (mouse.containsMouse ? Theme.hover : "transparent")

                IconImage {
                    id: icon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 30
                    asynchronous: true
                    // One-argument iconPath(): the oldest form, present in
                    // every Quickshell release.
                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon) : ""
                }

                // Shown when the theme has no such icon.
                Text {
                    anchors.centerIn: icon
                    visible: icon.status !== Image.Ready
                    text: "\u{F08C6}"
                    color: Theme.textDim
                    font.family: Theme.font
                    font.pixelSize: 22
                }

                Column {
                    anchors.left: icon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: row.modelData.name || ""
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: row.modelData.genericName || row.modelData.comment || ""
                        color: Theme.textDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selected = row.index
                    onClicked: root.launch(row.modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: root.apps.length === 0 ? "No applications found" : "No matches"
                color: Theme.textFaint
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
