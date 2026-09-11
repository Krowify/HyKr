// bluetoothctl-backed state -- blueman-manager (already used elsewhere
// in HyKr, e.g. waybar's bluetooth on-click-right) is the fallback GUI
// for anything this panel doesn't cover.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool powered: false
    property var connectedDevices: []
    property var pairedDevices: []

    // Set by BluetoothPanel from its own visibility. The dock bar itself only
    // ever reads `powered` (for the icon colour); connectedDevices/
    // pairedDevices are read exclusively by the panel. Enumerating them on
    // every tick meant two extra bluetoothctl processes -- each a fresh D-Bus
    // client -- every 4 seconds, forever, for a list nobody was looking at.
    property bool detailsWanted: false

    // Repopulate immediately on open rather than waiting up to one tick, so
    // the panel doesn't flash an empty device list.
    onDetailsWantedChanged: if (detailsWanted) devicesProc.running = true

    function refresh() {
        powerProc.running = true
        if (root.detailsWanted)
            devicesProc.running = true
    }

    function togglePower() {
        Quickshell.execDetached(["bluetoothctl", "power", root.powered ? "off" : "on"])
        refreshTimer.restart()
        // Powering off drops every connection, so the list the panel is
        // showing is stale the moment this runs.
        if (root.detailsWanted)
            devicesProc.running = true
    }

    function openManager() {
        Quickshell.execDetached(["sh", "-c", "command -v blueman-manager >/dev/null 2>&1 && blueman-manager"])
    }

    Timer {
        id: refreshTimer
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: powerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.powered = /Powered:\s*yes/i.test(text)
        }
    }

    Process {
        id: devicesProc
        command: ["sh", "-c", "bluetoothctl devices Connected; echo '---SPLIT---'; bluetoothctl devices Paired"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.split("---SPLIT---")
                const parseDevices = block => (block || "").trim().split("\n")
                    .filter(line => line.length > 0)
                    .map(line => {
                        const parts = line.split(" ")
                        const mac = parts[1] || ""
                        const name = parts.slice(2).join(" ")
                        return { mac: mac, name: name.length > 0 ? name : mac }
                    })
                const connected = parseDevices(sections[0])
                root.connectedDevices = connected
                // `bluetoothctl devices Paired` lists every paired device,
                // connected ones included, so BluetoothPanel rendered an
                // active headset twice -- once under "connected", again
                // under "paired". Keep the paired row for what's actually
                // just paired.
                const connectedMacs = connected.map(device => device.mac)
                root.pairedDevices = parseDevices(sections[1])
                    .filter(device => !connectedMacs.includes(device.mac))
            }
        }
    }
}
