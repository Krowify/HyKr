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
    property bool vpnAvailable: false // protonvpn-cli present
    property bool vpnGuiAvailable: false // a GUI ProtonVPN client present
    property bool vpnConnected: false
    property string vpnServer: ""

    // Set by NetworkPanel from its own visibility. The dock bar reads only
    // connectionType (the wifi/ethernet icon); every vpn* property is
    // panel-only. vpnProc shells out to protonvpn-cli, which spawns a Python
    // interpreter -- doing that every 5 seconds forever, to populate a panel
    // that is closed almost all of the time, was the single most expensive
    // thing this shell did at idle.
    property bool detailsWanted: false

    onDetailsWantedChanged: if (detailsWanted) vpnProc.running = true

    function refresh() {
        statusProc.running = true
        if (root.detailsWanted)
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

    // protonvpn-cli is confirmed absent on some machines this theme runs
    // on -- the "Quick Connect" button did nothing there since it only
    // ever shelled out to the CLI. This is the fallback: launch whatever
    // GUI ProtonVPN client is actually installed instead (the official
    // Electron app's binary is `protonvpn-app`; older packaging used
    // plain `protonvpn`; Flatpak is a last resort). `exec` hands off to
    // the first one found so the shell doesn't fall through to the rest
    // once a match runs.
    function openVpnApp() {
        Quickshell.execDetached(["sh", "-c",
            "command -v protonvpn-app >/dev/null 2>&1 && exec protonvpn-app; " +
            "command -v protonvpn >/dev/null 2>&1 && exec protonvpn; " +
            "command -v flatpak >/dev/null 2>&1 && exec flatpak run com.protonvpn.www"])
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
            "(command -v protonvpn-app >/dev/null 2>&1 || command -v protonvpn >/dev/null 2>&1 || " +
            "(command -v flatpak >/dev/null 2>&1 && flatpak info com.protonvpn.www >/dev/null 2>&1)) " +
            "&& echo GUI_AVAILABLE; " +
            "command -v protonvpn-cli >/dev/null 2>&1 && protonvpn-cli status 2>/dev/null || echo NOT_INSTALLED"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.vpnGuiAvailable = text.includes("GUI_AVAILABLE")
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
