// Clipboard history (Super+V), replacing
// `cliphist list | wofi --dmenu | cliphist decode | wl-copy`.
//
// cliphist still records the history (hyprland.lua's `wl-paste --watch
// cliphist store`); this only replaces the menu. Type to filter, Enter copies
// the selected entry back to the clipboard, Delete removes it from the
// history, Escape closes. An image entry is decoded on selection and shown in
// the preview pane, which the wofi menu could never do.
import Quickshell
import Quickshell.Io
import QtQuick

OverlayWindow {
    id: root

    surfaceName: "hykr-clipboard"
    cardWidth: 860
    cardHeight: 500

    property var entries: []
    property var pending: []
    property string query: ""
    property int selected: 0
    property string previewPath: ""

    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/hykr-clipboard"
    readonly property var results: root.filter(root.entries, root.query)
    readonly property var current: root.results.length > 0 ? root.results[Math.min(root.selected, root.results.length - 1)] : null

    onOpened: {
        search.text = "";
        root.query = "";
        root.selected = 0;
        root.previewPath = "";
        root.refresh();
        search.focusInput();
    }

    onCurrentChanged: root.preview()

    // "<id>\t<preview>" -> { line, id, text, image }
    function parse(line) {
        const tab = line.indexOf("\t");
        const text = tab >= 0 ? line.slice(tab + 1) : line;
        const m = /^\[\[ binary data .*\b(png|jpe?g|gif|bmp|webp)\b/i.exec(text);
        return { line: line, id: tab >= 0 ? line.slice(0, tab) : "", text: text, image: m ? m[1].toLowerCase() : "" };
    }

    function filter(list, rawQuery) {
        const q = String(rawQuery || "").trim().toLowerCase();
        if (q.length === 0)
            return list;
        return list.filter(e => e.text.toLowerCase().indexOf(q) >= 0);
    }

    function refresh() {
        root.pending = [];
        listProc.running = true;
    }

    function move(delta) {
        if (root.results.length === 0)
            return;
        root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta));
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function copy(entry) {
        if (!entry)
            return;
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
        root.open = false;
    }

    function remove(entry) {
        if (!entry)
            return;
        deleteProc.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line];
        deleteProc.running = true;
    }

    function preview() {
        const e = root.current;
        if (!e || !e.image) {
            root.previewPath = "";
            return;
        }
        const path = root.runtimeDir + "/" + e.id + "." + e.image;
        previewProc.target = path;
        previewProc.command = ["sh", "-c",
            // Decoded once per entry (ids are unique); the final -s check
            // makes an empty or failed decode exit non-zero, so the preview
            // never points at a file that isn't there.
            "mkdir -p \"$(dirname \"$2\")\" && { [ -s \"$2\" ] || printf '%s' \"$1\" | cliphist decode > \"$2\"; } && [ -s \"$2\" ]",
            "sh", e.line, path];
        previewProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    root.pending.push(root.parse(data));
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.entries = root.pending;
            root.pending = [];
            root.selected = Math.max(0, Math.min(root.selected, root.results.length - 1));
        }
    }

    Process {
        id: deleteProc
        onExited: (exitCode, exitStatus) => root.refresh()
    }

    Process {
        id: previewProc
        property string target: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.current && previewProc.target.indexOf("/" + root.current.id + ".") >= 0)
                root.previewPath = previewProc.target;
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
            placeholder: "Search clipboard  ·  Enter copies, Delete removes"
            glyph: "\u{F014C}"
            onTextChanged: {
                root.query = search.text;
                root.selected = 0;
                list.positionViewAtBeginning();
            }
            onAccepted: root.copy(root.current)
            onDismissed: root.open = false
            onNavigate: delta => root.move(delta)
            onDeleteRequested: root.remove(root.current)
        }

        Row {
            width: parent.width
            height: parent.height - search.height - parent.spacing
            spacing: 12

            ListView {
                id: list
                width: Math.round(parent.width * 0.58)
                height: parent.height
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
                    height: 38
                    radius: Theme.radiusSmall
                    color: row.index === root.selected ? Theme.selected : (mouse.containsMouse ? Theme.hover : "transparent")

                    Text {
                        id: kind
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.image ? "\u{F02E9}" : "\u{F0219}"
                        color: Theme.textDim
                        font.family: Theme.font
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.left: kind.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.image ? ("Image (" + row.modelData.image + ")") : row.modelData.text.replace(/\s+/g, " ")
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onEntered: root.selected = row.index
                        onClicked: mouseEvent => {
                            if (mouseEvent.button === Qt.MiddleButton)
                                root.remove(row.modelData);
                            else
                                root.copy(row.modelData);
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: root.entries.length === 0 ? "Clipboard history is empty" : "No matches"
                    color: Theme.textFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }

            // Preview: the decoded image, or the entry's full text.
            Rectangle {
                width: parent.width - list.width - parent.spacing
                height: parent.height
                radius: Theme.radiusSmall
                color: Theme.card

                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: root.previewPath.length > 0
                    source: Theme.fileUrl(root.previewPath)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    sourceSize.width: 600
                }

                Text {
                    anchors.fill: parent
                    anchors.margins: 12
                    visible: root.previewPath.length === 0
                    text: root.current ? (root.current.image ? "Loading preview…" : root.current.text) : ""
                    color: Theme.textDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                }
            }
        }
    }
}
