// Network quick panel (the bar's network icon, or the chevron on the control
// centre's Wi-Fi tile), so joining a network doesn't mean opening
// nm-connection-editor.
//
// - The switch turns the Wi-Fi radio on or off; the arrow rescans.
// - Networks: the connected one first, then by signal. Click a saved or open
//   network to join it; a secured new one opens a password box in place
//   (Enter or Connect). Click the connected one to disconnect. The bin
//   forgets a saved network.
// - Wired connection, when there is one.
// - ProtonVPN: connect / disconnect (moved here from the dock's old network
//   popup), or open the app when only the GUI client is installed.
//
// State from wifi.sh every 4s while open. A failed join says so in the panel
// and, for a secured network, asks for the password again.
import Quickshell
import Quickshell.Io
import QtQuick

QuickPanel {
    id: root

    title: "Network"
    surfaceName: "hykr-network"

    property string radio: ""
    property string wired: ""
    property var networks: []
    property var pending: []
    property string pendingRadio: ""
    property string pendingWired: ""

    property string busySsid: ""
    property string askPassword: ""    // ssid whose password box is open
    property string message: ""

    property string vpn: ""            // "cli" | "gui" | "none"
    property bool vpnConnected: false
    property string vpnServer: ""

    readonly property var sorted: root.networks.slice().sort((a, b) =>
        (b.inUse - a.inUse) || (b.signal - a.signal) || a.ssid.localeCompare(b.ssid))

    headerItems: [
        RoundButton {
            visible: root.radio === "on"
            size: 32
            glyphSize: 15
            glyph: "\u{F0450}"
            onClicked: root.rescan()
        },
        PillSwitch {
            visible: root.radio === "on" || root.radio === "off"
            checked: root.radio === "on"
            onToggled: root.act("", ["nmcli", "radio", "wifi", root.radio === "on" ? "off" : "on"], "", "")
        }
    ]

    onOpenChanged: {
        if (root.open) {
            root.rescan();
            vpnProc.running = true;
        } else {
            root.askPassword = "";
            root.message = "";
        }
    }

    function rescan() {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
        rescanRefresh.restart();
    }

    function strengthGlyph(s) {
        if (s >= 75) return "\u{F0928}";
        if (s >= 50) return "\u{F0925}";
        if (s >= 25) return "\u{F0922}";
        return "\u{F091F}";
    }

    // One action at a time. `failure`: what to say if it fails; `retrySsid`:
    // a secured network to ask the password for again on failure.
    function act(ssid, cmd, failure, retrySsid) {
        if (actionProc.running)
            return;
        root.busySsid = ssid;
        root.message = "";
        actionProc.failure = failure;
        actionProc.retrySsid = retrySsid;
        actionProc.command = cmd;
        actionProc.running = true;
    }

    function choose(n) {
        if (n.inUse) {
            // The active Wi-Fi connection, whatever its profile is called.
            root.act(n.ssid, ["sh", "-c",
                "c=\"$(nmcli -t --escape no -f TYPE,NAME con show --active | awk -F: '$1 == \"802-11-wireless\" { sub(/^[^:]*:/, \"\"); print; exit }')\"; [ -n \"$c\" ] && nmcli con down id \"$c\""],
                "Couldn't disconnect from " + n.ssid + ".", "");
        } else if (n.saved || n.security.length === 0) {
            root.askPassword = "";
            root.act(n.ssid, ["nmcli", "dev", "wifi", "connect", n.ssid],
                "Couldn't join " + n.ssid + ".", n.security.length > 0 ? n.ssid : "");
        } else {
            root.askPassword = root.askPassword === n.ssid ? "" : n.ssid;
            root.message = "";
        }
    }

    function join(ssid, password) {
        if (password.length === 0)
            return;
        root.act(ssid, ["nmcli", "dev", "wifi", "connect", ssid, "password", password],
            "Couldn't join " + ssid + " — check the password.", ssid);
    }

    Timer {
        interval: 4000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!stateProc.running) stateProc.running = true
    }

    Timer {
        id: rescanRefresh
        interval: 3500
        onTriggered: if (!stateProc.running) stateProc.running = true
    }

    Process {
        id: stateProc
        command: ["bash", Quickshell.shellPath("wifi.sh")]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split("\t");
                if (f[0] === "radio")
                    root.pendingRadio = f[1];
                else if (f[0] === "wired")
                    root.pendingWired = f[1];
                else if (f[0] === "net" && f.length >= 6)
                    root.pending.push({
                        ssid: f[1], signal: parseInt(f[2]) || 0, security: f[3],
                        inUse: f[4] === "yes", saved: f[5] === "yes"
                    });
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.radio = root.pendingRadio;
            root.wired = root.pendingWired;
            root.networks = root.pending;
            root.pending = [];
            root.pendingWired = "";
        }
    }

    Process {
        id: actionProc
        property string failure: ""
        property string retrySsid: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (actionProc.failure.length > 0)
                    root.message = actionProc.failure;
                if (actionProc.retrySsid.length > 0)
                    root.askPassword = actionProc.retrySsid;
            } else {
                root.askPassword = "";
            }
            root.busySsid = "";
            if (!stateProc.running)
                stateProc.running = true;
        }
    }

    // ProtonVPN: the CLI's status when it's installed, otherwise whether a
    // GUI client is there to open. Same detection the dock always used.
    Process {
        id: vpnProc
        command: ["sh", "-c",
            "if command -v protonvpn-cli >/dev/null 2>&1; then echo CLI; protonvpn-cli status 2>/dev/null; " +
            "elif command -v protonvpn-app >/dev/null 2>&1 || command -v protonvpn >/dev/null 2>&1 || " +
            "(command -v flatpak >/dev/null 2>&1 && flatpak info com.protonvpn.www >/dev/null 2>&1); then echo GUI; " +
            "else echo NONE; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.vpn = text.indexOf("CLI") === 0 ? "cli" : (text.indexOf("GUI") === 0 ? "gui" : "none");
                root.vpnConnected = root.vpn === "cli" && /Status:\s*Connected/i.test(text);
                const m = text.match(/Server:\s*(\S+)/i);
                root.vpnServer = m ? m[1] : "";
            }
        }
    }

    Timer {
        interval: 10000
        running: root.open && root.vpn === "cli"
        repeat: true
        onTriggered: if (!vpnProc.running) vpnProc.running = true
    }

    function vpnToggle() {
        Quickshell.execDetached(["protonvpn-cli", root.vpnConnected ? "disconnect" : "connect"].concat(root.vpnConnected ? [] : ["--fastest"]));
        vpnRefresh.restart();
    }

    Timer {
        id: vpnRefresh
        interval: 4000
        onTriggered: if (!vpnProc.running) vpnProc.running = true
    }

    // ---------------- body ----------------
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

    ListRow {
        visible: root.wired.length > 0
        glyph: "\u{F0200}"
        title: "Wired"
        detail: root.wired
        active: true
    }

    SectionLabel {
        visible: root.radio !== "none" && root.radio !== ""
        text: "WI-FI"
    }

    Text {
        width: parent.width
        visible: root.radio === "off"
        text: "Wi-Fi is off."
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    Repeater {
        model: root.radio === "on" ? root.sorted : []
        delegate: Column {
            id: net
            required property var modelData
            width: parent.width
            spacing: 4

            ListRow {
                glyph: root.strengthGlyph(net.modelData.signal)
                title: net.modelData.ssid
                detail: (net.modelData.inUse ? "Connected" : (net.modelData.saved ? "Saved" : (net.modelData.security.length > 0 ? "Secured" : "Open")))
                    + " · " + net.modelData.signal + "%"
                active: net.modelData.inUse
                busy: root.busySsid === net.modelData.ssid
                trailing: net.modelData.security.length > 0 && !net.modelData.inUse ? "\u{F033E}" : ""
                secondaryGlyph: net.modelData.saved ? "\u{F0A7A}" : ""
                onClicked: root.choose(net.modelData)
                onSecondaryClicked: root.act(net.modelData.ssid, ["nmcli", "con", "delete", "id", net.modelData.ssid],
                    "Couldn't forget " + net.modelData.ssid + ".", "")
            }

            // Password box for a secured network you haven't joined before.
            Rectangle {
                width: parent.width
                height: 44
                visible: root.askPassword === net.modelData.ssid
                radius: Theme.radiusSmall
                color: Theme.card
                border.width: 1
                border.color: pw.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55) : Theme.border

                onVisibleChanged: if (visible) { pw.text = ""; pw.forceActiveFocus(); }

                TextInput {
                    id: pw
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: reveal.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: reveal.shown ? TextInput.Normal : TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    clip: true
                    onAccepted: root.join(net.modelData.ssid, pw.text)
                    Keys.onEscapePressed: root.askPassword = ""

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: pw.text.length === 0
                        text: "Password"
                        color: Theme.textFaint
                        font: pw.font
                    }
                }

                RoundButton {
                    id: reveal
                    property bool shown: false
                    anchors.right: go.left
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    glyphSize: 14
                    glyph: reveal.shown ? "\u{F0209}" : "\u{F0208}"
                    onClicked: reveal.shown = !reveal.shown
                }

                RoundButton {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    size: 32
                    glyphSize: 14
                    accent: true
                    glyph: "\u{F0054}"
                    onClicked: root.join(net.modelData.ssid, pw.text)
                }
            }
        }
    }

    Text {
        width: parent.width
        visible: root.radio === "on" && root.networks.length === 0
        text: "Looking for networks…"
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    Text {
        width: parent.width
        visible: root.radio === "none" && root.wired.length === 0
        text: "No network devices found."
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    // ---------------- VPN ----------------
    SectionLabel {
        visible: root.vpn === "cli" || root.vpn === "gui"
        text: "VPN"
    }

    ListRow {
        visible: root.vpn === "cli"
        glyph: "\u{F0582}"
        title: "ProtonVPN"
        detail: root.vpnConnected ? ("Connected" + (root.vpnServer.length > 0 ? " · " + root.vpnServer : "")) : "Not connected · click for the fastest server"
        active: root.vpnConnected
        onClicked: root.vpnToggle()
    }

    ListRow {
        visible: root.vpn === "gui"
        glyph: "\u{F0582}"
        title: "ProtonVPN"
        detail: "Open the app"
        onClicked: {
            root.open = false;
            Quickshell.execDetached(["sh", "-c",
                "command -v protonvpn-app >/dev/null 2>&1 && exec protonvpn-app; " +
                "command -v protonvpn >/dev/null 2>&1 && exec protonvpn; " +
                "command -v flatpak >/dev/null 2>&1 && exec flatpak run com.protonvpn.www"]);
        }
    }

    // For what this panel doesn't do (enterprise Wi-Fi, static IPs, ...).
    Text {
        width: parent.width
        topPadding: 4
        horizontalAlignment: Text.AlignRight
        text: "Network settings ›"
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.open = false;
                Quickshell.execDetached(["sh", "-c",
                    "command -v nm-connection-editor >/dev/null 2>&1 && exec nm-connection-editor || exec kitty nmtui"]);
            }
        }
    }
}
