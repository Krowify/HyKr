// Control centre (Super+M, Super+S), replacing the old Super+M Quickshell
// panel and the Super+S wofi quick-settings menu (quick_settings.sh).
//
// Anchored top-right; as a normal (non-ignoring) layer surface it sits below
// whichever bar the theme runs. A click anywhere else closes it (Hyprland
// focus grab), so does Escape.
//
// State comes from status.sh -- one process every 2s, and only while open.
// Toggles run their command and refresh shortly after. Notifications live in
// the bar's process, so that card asks the bar (dock_ipc.sh) rather than
// owning a notification server of its own: a bug here can't take
// notifications down with it.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property bool open: false
    property var st: ({})
    property var pendingSt: ({})

    signal themesWanted()
    signal wallpaperWanted()

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string hypr: root.home + "/.config/hypr"

    visible: root.open
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 8; right: 8 }
    implicitWidth: 400
    implicitHeight: body.implicitHeight + 32
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "hykr-control"

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.open = false
    }

    onOpenChanged: {
        if (root.open) {
            root.now = new Date();
            keys.forceActiveFocus();
        }
    }

    // ---------------- state ----------------
    function on(key) { return root.st[key] === "on"; }
    function num(key) {
        const n = parseInt(root.st[key]);
        return isFinite(n) ? n : -1;
    }

    Timer {
        interval: 2000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    // After a toggle: give the command a moment to take effect, then re-read.
    Timer {
        id: refreshSoon
        interval: 450
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["bash", Quickshell.shellPath("status.sh")]
        stdout: SplitParser {
            onRead: data => {
                const i = data.indexOf("=");
                if (i > 0)
                    root.pendingSt[data.slice(0, i)] = data.slice(i + 1);
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.st = root.pendingSt;
            root.pendingSt = {};
        }
    }

    function run(cmd) {
        Quickshell.execDetached(cmd);
        refreshSoon.restart();
    }

    // Close first, for actions that open something else or take the screen.
    function runClosed(cmd) {
        root.open = false;
        Quickshell.execDetached(cmd);
    }

    // ---------------- clock ----------------
    property var now: new Date()
    Timer {
        interval: 1000
        running: root.open
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---------------- media ----------------
    // The playing player if there is one, else the first one there is (a
    // paused track still gets its card -- it doesn't vanish on pause).
    readonly property var player: {
        const ps = Mpris.players.values;
        for (let i = 0; i < ps.length; i++) {
            if (ps[i] && ps[i].isPlaying)
                return ps[i];
        }
        return ps.length > 0 ? ps[0] : null;
    }

    // MprisPlayer.position only updates when asked to.
    Timer {
        interval: 1000
        running: root.open && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // ---------------- building blocks ----------------
    component Glyph: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component Label: Text {
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
    }

    component Card: Rectangle {
        radius: Theme.radius - 4
        color: Theme.card
    }

    // A two-line toggle: icon, title, state. `active` fills it with the accent.
    component Tile: Rectangle {
        id: tile
        property string glyph: ""
        property string title: ""
        property string detail: ""
        property bool active: false
        property bool available: true
        signal clicked()

        height: 58
        radius: Theme.radius - 4
        opacity: tile.available ? 1 : 0.45
        color: tile.active ? Theme.accent : (tileMouse.containsMouse ? Theme.hover : Theme.card)

        Rectangle {
            id: tileIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: tile.active ? Qt.rgba(0, 0, 0, 0.14) : Theme.hover

            Glyph {
                anchors.centerIn: parent
                text: tile.glyph
                color: tile.active ? Theme.onAccent : Theme.text
            }
        }

        Column {
            anchors.left: tileIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                text: tile.title
                color: tile.active ? Theme.onAccent : Theme.text
                font.bold: true
            }
            Label {
                width: parent.width
                text: tile.detail
                color: tile.active ? Theme.onAccent : Theme.textDim
                font.pixelSize: Theme.fontSmall
                opacity: 0.85
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: tile.available
            onClicked: tile.clicked()
        }
    }

    // A slider: drag or click the track. Reports a 0-100 value on release (and
    // while dragging, throttled), and ignores status refreshes while held so
    // the knob doesn't jump back under your finger.
    component Slider: Item {
        id: slider
        property string glyph: ""
        property int value: 0
        property bool muted: false
        readonly property bool held: track.pressed
        signal moved(int value)
        signal glyphClicked()

        height: 36

        Glyph {
            id: sliderGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            text: slider.glyph
            color: slider.muted ? Theme.textFaint : Theme.text

            MouseArea {
                anchors.fill: parent
                onClicked: slider.glyphClicked()
            }
        }

        Rectangle {
            id: bar
            anchors.left: sliderGlyph.right
            anchors.leftMargin: 8
            anchors.right: percent.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 10
            radius: 5
            color: Theme.hover

            Rectangle {
                width: Math.max(bar.height, bar.width * Math.max(0, Math.min(100, track.pressed ? track.dragValue : slider.value)) / 100)
                height: parent.height
                radius: parent.radius
                color: slider.muted ? Theme.textFaint : Theme.accent
            }

            MouseArea {
                id: track
                property int dragValue: 0
                anchors.fill: parent
                anchors.margins: -10
                function valueAt(x) {
                    return Math.round(Math.max(0, Math.min(100, (x - 10) / bar.width * 100)));
                }
                onPressed: mouse => { track.dragValue = track.valueAt(mouse.x); slider.moved(track.dragValue); }
                onPositionChanged: mouse => {
                    if (!track.pressed)
                        return;
                    const v = track.valueAt(mouse.x);
                    if (v !== track.dragValue) {
                        track.dragValue = v;
                        throttle.restart();
                    }
                }
                onReleased: slider.moved(track.dragValue)
            }

            Timer {
                id: throttle
                interval: 80
                onTriggered: slider.moved(track.dragValue)
            }
        }

        Label {
            id: percent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: (track.pressed ? track.dragValue : slider.value) + "%"
            color: Theme.textDim
            font.pixelSize: Theme.fontSmall
        }
    }

    component Stat: Column {
        id: stat
        property string glyph: ""
        property string title: ""
        property int value: -1
        spacing: 4

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Glyph { text: stat.glyph; font.pixelSize: 13; color: Theme.textDim }
            Label { text: stat.value >= 0 ? stat.value + "%" : "–"; font.bold: true }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 4
            radius: 2
            color: Theme.hover
            Rectangle {
                width: parent.width * Math.max(0, stat.value) / 100
                height: parent.height
                radius: 2
                color: stat.value >= 85 ? Theme.red : Theme.accent
            }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: stat.title
            color: Theme.textFaint
            font.pixelSize: Theme.fontSmall - 1
        }
    }

    component IconButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool accent: false
        signal clicked()

        width: 38
        height: 38
        radius: 19
        color: btn.accent ? Theme.accent : (btnMouse.containsMouse ? Theme.hover : "transparent")

        Glyph {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.accent ? Theme.onAccent : Theme.text
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    // ---------------- layout ----------------
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.open = false
        }

        Column {
            id: body
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 10

            // Clock, date, and the actions that leave this panel.
            Item {
                width: parent.width
                height: 54

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: Qt.formatTime(root.now, "hh:mm")
                        font.pixelSize: 28
                        font.bold: true
                    }
                    Label {
                        text: Qt.formatDate(root.now, "dddd, MMMM d")
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSmall
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    IconButton { glyph: "\u{F03D8}"; onClicked: { root.open = false; root.themesWanted(); } }
                    IconButton { glyph: "\u{F02E9}"; onClicked: { root.open = false; root.wallpaperWanted(); } }
                    IconButton { glyph: "\u{F033E}"; onClicked: root.runClosed([root.hypr + "/lock.sh"]) }
                    IconButton { glyph: "\u{F0425}"; onClicked: root.runClosed(["wlogout"]) }
                }
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8
                readonly property real cell: (width - spacing) / 2

                Tile {
                    width: parent.cell
                    glyph: root.on("wifi") ? "\u{F05A9}" : "\u{F05AA}"
                    title: "Wi-Fi"
                    detail: root.st.wifi === "none" ? "Unavailable" : (root.on("wifi") ? (root.st.ssid || "On") : "Off")
                    active: root.on("wifi")
                    available: root.st.wifi !== "none"
                    onClicked: root.run(["sh", "-c", "nmcli radio wifi \"$(nmcli -t -f WIFI general | grep -q enabled && echo off || echo on)\""])
                }
                Tile {
                    width: parent.cell
                    glyph: root.on("bt") ? "\u{F00AF}" : "\u{F00B2}"
                    title: "Bluetooth"
                    detail: root.st.bt === "none" ? "Unavailable" : (root.on("bt") ? (root.st.btdev || "On") : "Off")
                    active: root.on("bt")
                    available: root.st.bt !== "none"
                    onClicked: root.run(["sh", "-c", "bluetoothctl power \"$(bluetoothctl show | grep -q 'Powered: yes' && echo off || echo on)\""])
                }
                Tile {
                    width: parent.cell
                    glyph: root.st.dnd === "true" ? "\u{F009B}" : "\u{F009A}"
                    title: "Do Not Disturb"
                    detail: root.st.dnd === "true" ? "On" : "Off"
                    active: root.st.dnd === "true"
                    onClicked: root.run([root.hypr + "/dock_ipc.sh", "toggle-dnd"])
                }
                Tile {
                    width: parent.cell
                    glyph: "\u{F0176}"
                    title: "Caffeine"
                    // Caffeine on = hypridle stopped (nothing locks or sleeps).
                    detail: root.on("idle") ? "Off" : "On · no auto-lock"
                    active: root.st.idle === "off"
                    onClicked: root.run(["sh", "-c", "pkill -x hypridle || exec hypridle"])
                }
                Tile {
                    width: parent.cell
                    glyph: "\u{F0594}"
                    title: "Night Light"
                    detail: root.on("night") ? "On · 5000K" : "Off"
                    active: root.on("night")
                    // -t 5000: same as the Super+Shift+N bind.
                    onClicked: root.run(["sh", "-c", "pkill -x hyprsunset || exec hyprsunset -t 5000"])
                }
                Tile {
                    width: parent.cell
                    glyph: "\u{F001D}"
                    title: "Airplane"
                    readonly property bool airplane: root.st.wifi !== "on" && root.st.bt !== "on"
                    detail: airplane ? "Radios off" : "Off"
                    active: airplane && (root.st.wifi === "off" || root.st.bt === "off")
                    onClicked: root.run([root.hypr + "/fn_keys.sh", "airplane"])
                }
            }

            Card {
                width: parent.width
                height: sliders.implicitHeight + 16

                Column {
                    id: sliders
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Slider {
                        width: parent.width
                        visible: root.num("volume") >= 0
                        glyph: root.st.muted === "true" ? "\u{F075F}" : "\u{F057E}"
                        muted: root.st.muted === "true"
                        value: Math.max(0, root.num("volume"))
                        onMoved: v => Quickshell.execDetached(["pamixer", "--set-volume", String(v)])
                        onGlyphClicked: root.run(["pamixer", "-t"])
                    }
                    Slider {
                        width: parent.width
                        visible: root.num("brightness") >= 0
                        glyph: "\u{F00DF}"
                        value: Math.max(0, root.num("brightness"))
                        onMoved: v => Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.max(1, v) + "%"])
                    }
                }
            }

            Card {
                width: parent.width
                height: 64

                Row {
                    anchors.centerIn: parent
                    spacing: 40
                    Stat { glyph: "\u{F0EE0}"; title: "CPU"; value: root.num("cpu") }
                    Stat { glyph: "\u{F035B}"; title: "RAM"; value: root.num("ram") }
                    Stat { glyph: "\u{F02CA}"; title: "Disk"; value: root.num("disk") }
                }
            }

            // Media: whatever MPRIS player is playing (or the last one there is).
            Card {
                width: parent.width
                height: 92
                visible: root.player !== null

                Rectangle {
                    id: art
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72
                    height: 72
                    radius: Theme.radiusSmall
                    color: Theme.hover
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: root.player ? (root.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 144
                    }
                    Glyph {
                        anchors.centerIn: parent
                        visible: !root.player || !root.player.trackArtUrl
                        text: "\u{F075A}"
                        color: Theme.textFaint
                        font.pixelSize: 26
                    }
                }

                Column {
                    anchors.left: art.right
                    anchors.leftMargin: 12
                    anchors.right: controls.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Label {
                        width: parent.width
                        text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
                        font.bold: true
                    }
                    Label {
                        width: parent.width
                        text: root.player ? (root.player.trackArtist || "") : ""
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSmall
                    }
                    Item {
                        width: parent.width
                        height: 14
                        visible: root.player !== null && root.player.length > 0

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: times.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4
                            radius: 2
                            color: Theme.hover
                            Rectangle {
                                width: root.player && root.player.length > 0
                                    ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                            }
                        }
                        Label {
                            id: times
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.player ? root.clock(root.player.position) + " / " + root.clock(root.player.length) : ""
                            color: Theme.textFaint
                            font.pixelSize: Theme.fontSmall - 2
                        }
                    }
                }

                Row {
                    id: controls
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    IconButton {
                        glyph: "\u{F04AE}"
                        opacity: root.player && root.player.canGoPrevious ? 1 : 0.35
                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                    }
                    IconButton {
                        glyph: root.player && root.player.isPlaying ? "\u{F03E4}" : "\u{F040A}"
                        accent: true
                        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                    }
                    IconButton {
                        glyph: "\u{F04AD}"
                        opacity: root.player && root.player.canGoNext ? 1 : 0.35
                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                    }
                }
            }

            // Notifications are the bar's; this opens its notification centre.
            Card {
                width: parent.width
                height: 48
                color: notifMouse.containsMouse ? Theme.hover : Theme.card

                Glyph {
                    id: bell
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.st.dnd === "true" ? "\u{F009B}" : "\u{F009A}"
                }
                Label {
                    anchors.left: bell.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const n = Math.max(0, root.num("notifications"));
                        return n === 0 ? "No notifications" : (n === 1 ? "1 notification" : n + " notifications");
                    }
                }
                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Open ›"
                    color: Theme.accent
                    font.pixelSize: Theme.fontSmall
                }
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.runClosed([root.hypr + "/dock_ipc.sh", "toggle-notifications"])
                }
            }

            Item {
                width: parent.width
                height: 34

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: shotLabel.implicitWidth + 44
                        height: 34
                        radius: 17
                        color: shotMouse.containsMouse ? Theme.hover : Theme.card
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Glyph { text: "\u{F0E51}"; font.pixelSize: 14 }
                            Label { id: shotLabel; text: "Screenshot region"; font.pixelSize: Theme.fontSmall }
                        }
                        MouseArea {
                            id: shotMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            // The panel closes first, so it isn't in the shot.
                            onClicked: root.runClosed(["sh", "-c", "sleep 0.3; grim -g \"$(slurp)\" - | wl-copy"])
                        }
                    }
                }
            }
        }
    }
}
