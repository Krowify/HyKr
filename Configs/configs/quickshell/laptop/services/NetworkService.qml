// nmcli-backed connection status (wifi vs ethernet vs disconnected) plus
// best-effort ProtonVPN status via protonvpn-cli, guarded behind
// command -v since it's an optional CLI (same defensive pattern the rest
// of HyKr uses for pywalfox/swayosd -- not in pkg_core.lst).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string connectionType: "disconnected" // "wifi" | "ethernet" | "disconnected"
    property string connectionName: ""
    property bool vpnAvailable: false
    property bool vpnConnected: false
    property string vpnServer: ""

    function refresh() {
        statusProc.running = true
        vpnProc.running = true
    }

    function openNetworkManager() {
        Quickshell.execDetached(["sh", "-c",
            "command -v nm-connection-editor >/dev/null 2>&1 && nm-connection-editor || kitty nmtui"])
    }

    function vpnConnect() {
        Quickshell.execDetached(["sh", "-c",
            "command -v protonvpn-cli >/dev/null 2>&1 && protonvpn-cli connect --fastest"])
        refreshTimer.restart()
    }

    function vpnDisconnect() {
        Quickshell.execDetached(["sh", "-c",
            "command -v protonvpn-cli >/dev/null 2>&1 && protonvpn-cli disconnect"])
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev status 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let type = "disconnected"
                let name = ""
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(":")
                    if (parts.length < 3 || parts[1] !== "connected")
                        continue
                    if (parts[0].includes("wifi")) {
                        type = "wifi"
                        name = parts[2]
                        break
                    }
                    if (parts[0].includes("ethernet")) {
                        type = "ethernet"
                        name = parts[2]
                    }
                }
                root.connectionType = type
                root.connectionName = name
            }
        }
    }

    Process {
        id: vpnProc
        command: ["sh", "-c",
            "command -v protonvpn-cli >/dev/null 2>&1 && protonvpn-cli status 2>/dev/null || echo NOT_INSTALLED"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("NOT_INSTALLED")) {
                    root.vpnAvailable = false
                    root.vpnConnected = false
                    return
                }
                root.vpnAvailable = true
                root.vpnConnected = /Status:\s*Connected/i.test(text)
                const m = text.match(/Server:\s*(\S+)/i)
                root.vpnServer = m ? m[1] : ""
            }
        }
    }
}
