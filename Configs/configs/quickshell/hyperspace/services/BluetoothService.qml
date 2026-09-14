// Copied from ../../laptop/services/BluetoothService.qml and extended with
// per-device connect/disconnect (see ../README.md for why the two docks
// each carry their own copy). Everything apart from that pair of functions
// is unchanged from the Laptop version, so parsing/polling fixes belong in
// BOTH files. Pairing a NEW device is still blueman-manager's job -- the
// "Open Bluetooth Manager" button at the bottom of the panel.
//
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

    // Set by BluetoothPanel from its own visibility. Unlike the Laptop
    // dock -- which polls the device lists ONLY while its panel is open,
    // because its bar icon reads nothing but `powered` -- Hyperspace's bar
    // icon distinguishes "on" from "on, with something connected", so the
    // lists have to stay live even with every panel shut. The compromise is
    // cadence, not gating: the device enumeration (an sh plus two
    // bluetoothctl D-Bus clients per run) drops to once every 15 seconds
    // while nothing is looking at the detail, and only tightens to the
    // 4-second tick while the panel is actually open.
    property bool detailsWanted: false

    // Repopulate immediately on open rather than waiting up to one tick, so
    // the panel doesn't flash a stale device list.
    onDetailsWantedChanged: if (detailsWanted) devicesProc.running = true

    function refresh() {
        powerProc.running = true
    }

    function togglePower() {
        Quickshell.execDetached(["bluetoothctl", "power", root.powered ? "off" : "on"])
        refreshTimer.restart()
        // Powering off drops every connection, so both the panel's list and
        // the bar's icon are stale the moment this runs.
        deviceTimer.restart()
        devicesProc.running = true
    }

    // Per-device actions for the panel's device rows. `bluetoothctl connect`
    // exits as soon as the connection attempt is handed off, not when the
    // device is actually up, so the follow-up poll (rather than this call's
    // own exit) is what moves the device between the connected and paired
    // lists a second or two later. restart()ing deviceTimer is what makes
    // that poll happen promptly instead of up to a full interval later.
    function connectDevice(mac) {
        if (!mac)
            return
        Quickshell.execDetached(["bluetoothctl", "connect", mac])
        deviceTimer.restart()
    }

    function disconnectDevice(mac) {
        if (!mac)
            return
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac])
        deviceTimer.restart()
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

    // Changing `interval` on a running Timer restarts it, so an open panel
    // gets its first tight poll straight away rather than finishing out the
    // 15-second one it was mid-way through.
    Timer {
        id: deviceTimer
        interval: root.detailsWanted ? 4000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: devicesProc.running = true
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
