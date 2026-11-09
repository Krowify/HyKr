// Bluetooth quick panel (the bar's Bluetooth icon, or the chevron on the
// control centre's Bluetooth tile), so connecting a device doesn't mean
// opening Blueman.
//
// - The switch powers the adapter.
// - Your devices: click to connect or disconnect; the bin forgets one.
// - Scan finds new devices for 20s; click one to pair, trust (so it
//   reconnects by itself next time) and connect it.
//
// State from bluetooth.sh every 3s while open. One action runs at a time; a
// failure says so in the panel. A device that needs a PIN typed in can't be
// paired from here (bluetoothctl has no way to ask you for it) -- the
// message points at Bluetooth settings for that rare case.
import Quickshell
import Quickshell.Io
import QtQuick

QuickPanel {
    id: root

    title: "Bluetooth"
    surfaceName: "hykr-bluetooth"

    property string power: ""
    property var devices: []
    property var pending: []
    property string pendingPower: ""
    property bool scanning: false
    property string busyMac: ""
    property string message: ""

    readonly property var known: root.devices.filter(d => d.paired)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var found: root.devices.filter(d => !d.paired)

    headerItems: [
        RoundButton {
            visible: root.power === "on"
            size: 32
            glyphSize: 15
            glyph: root.scanning ? "\u{F04DB}" : "\u{F0450}"
            onClicked: root.scanning ? root.stopScan() : root.startScan()
        },
        PillSwitch {
            visible: root.power !== "none" && root.power !== ""
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            checked: root.power === "on"
            onToggled: root.act("", ["bluetoothctl", "power", root.power === "on" ? "off" : "on"], "")
        }
    ]

    onOpenChanged: {
        if (!root.open) {
            root.stopScan();
            root.message = "";
        }
    }

    function glyphFor(d) {
        const i = d.icon || "";
        if (i.indexOf("audio") === 0)
            return "\u{F02CB}";
        if (i === "input-mouse")
            return "\u{F037D}";
        if (i === "input-keyboard")
            return "\u{F030C}";
        if (i === "input-gaming")
            return "\u{F0297}";
        if (i === "phone")
            return "\u{F011C}";
        if (i === "computer")
            return "\u{F0379}";
        return "\u{F00AF}";
    }

    function startScan() {
        root.message = "";
        root.scanning = true;
        scanProc.running = true;
    }

    function stopScan() {
        scanProc.running = false;
        root.scanning = false;
    }

    // One action at a time; `failure` is what to say if it fails.
    function act(mac, cmd, failure) {
        if (actionProc.running)
            return;
        root.busyMac = mac;
        root.message = "";
        actionProc.failure = failure;
        actionProc.command = cmd;
        actionProc.running = true;
    }

    function toggle(d) {
        if (d.connected)
            root.act(d.mac, ["bluetoothctl", "disconnect", d.mac], "Couldn't disconnect " + d.name + ".");
        else
            root.act(d.mac, ["bluetoothctl", "connect", d.mac], "Couldn't connect to " + d.name + " — is it on and in range?");
    }

    function pair(d) {
        root.act(d.mac, ["sh", "-c", "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\"", "sh", d.mac],
            "Pairing with " + d.name + " failed. Put it in pairing mode and try again; a keyboard asking for a PIN needs Bluetooth settings.");
    }

    Timer {
        interval: 3000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!stateProc.running) stateProc.running = true
    }

    Process {
        id: stateProc
        command: ["bash", Quickshell.shellPath("bluetooth.sh")]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split("\t");
                if (f[0] === "power")
                    root.pendingPower = f[1];
                else if (f[0] === "dev" && f.length >= 6)
                    root.pending.push({
                        mac: f[1], name: f[2], paired: f[3] === "yes", connected: f[4] === "yes",
                        icon: f[5], battery: f.length > 6 ? f[6] : ""
                    });
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.power = root.pendingPower;
            root.devices = root.pending;
            root.pending = [];
        }
    }

    Process {
        id: scanProc
        command: ["timeout", "20", "bluetoothctl", "scan", "on"]
        onExited: (exitCode, exitStatus) => root.scanning = false
    }

    Process {
        id: actionProc
        property string failure: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && actionProc.failure.length > 0)
                root.message = actionProc.failure;
            root.busyMac = "";
            if (!stateProc.running)
                stateProc.running = true;
        }
    }

    // ---------------- body ----------------
    Text {
        width: parent.width
        visible: root.power === "none"
        text: "No Bluetooth adapter found."
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    Text {
        width: parent.width
        visible: root.power === "off"
        text: "Bluetooth is off."
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    Rectangle {
        width: parent.width
        visible: root.message.length > 0
        height: msg.implicitHeight + 16
        radius: Theme.radiusSmall
        color: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)

        Text {
            id: msg
            anchors.fill: parent
            anchors.margins: 8
            text: root.message
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
        }
    }

    SectionLabel {
        visible: root.power === "on" && root.known.length > 0
        text: "MY DEVICES"
    }

    Repeater {
        model: root.power === "on" ? root.known : []
        delegate: ListRow {
            required property var modelData
            glyph: root.glyphFor(modelData)
            title: modelData.name
            detail: modelData.connected
                ? ("Connected" + (modelData.battery.length > 0 ? " · " + modelData.battery + "%" : ""))
                : "Not connected"
            active: modelData.connected
            busy: root.busyMac === modelData.mac
            secondaryGlyph: "\u{F0A7A}"
            onClicked: root.toggle(modelData)
            onSecondaryClicked: root.act(modelData.mac, ["bluetoothctl", "remove", modelData.mac], "Couldn't forget " + modelData.name + ".")
        }
    }

    SectionLabel {
        visible: root.power === "on" && (root.scanning || root.found.length > 0)
        text: root.scanning ? "SEARCHING…" : "AVAILABLE"
    }

    Repeater {
        model: root.power === "on" ? root.found : []
        delegate: ListRow {
            required property var modelData
            glyph: root.glyphFor(modelData)
            title: modelData.name
            detail: "Click to pair"
            busy: root.busyMac === modelData.mac
            onClicked: root.pair(modelData)
        }
    }

    Text {
        width: parent.width
        visible: root.power === "on" && root.known.length === 0 && root.found.length === 0 && !root.scanning
        text: "No devices yet — press \u{F0450} to search."
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
    }

    // For what bluetoothctl can't do from here (a PIN prompt).
    Text {
        width: parent.width
        topPadding: 4
        horizontalAlignment: Text.AlignRight
        text: "Bluetooth settings ›"
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.open = false;
                Quickshell.execDetached(["sh", "-c", "command -v blueman-manager >/dev/null 2>&1 && exec blueman-manager"]);
            }
        }
    }
}
