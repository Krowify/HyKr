// sysfs-backed battery state (/sys/class/power_supply), matching the
// Process + Timer polling the rest of these services use. Read straight
// from sysfs rather than through UPower's DBus interface: every value
// the dock needs is two files, sysfs is always present on a laptop with
// no daemon to depend on, and HyKr already avoids adding packages for
// things the kernel exposes directly (see pkg_core.lst).
//
// `available` stays false on machines with no battery (this same shell
// config runs on the desktop's three monitors too), so DockBar can just
// hide the icon there instead of showing a permanently empty one.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property int percent: 0
    // Raw sysfs status: "Charging" | "Discharging" | "Full" |
    // "Not charging" | "Unknown"
    property string status: "Unknown"

    readonly property bool charging: status === "Charging"
    // "Not charging" is what a plugged-in battery sitting at its charge
    // limit reports (MSI/Lenovo firmware conservation modes do this all
    // day), so it counts as on-AC even though it isn't taking charge.
    readonly property bool plugged: charging || status === "Full" || status === "Not charging"
    readonly property bool low: available && !plugged && percent <= 15

    function refresh() {
        batteryProc.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: batteryProc
        // First real system battery wins. `type` filters out the AC
        // adapter (type=Mains), and `scope` filters out peripherals that
        // also register as batteries -- a connected Bluetooth mouse or
        // headset shows up here as type=Battery, scope=Device, and would
        // otherwise be reported as the laptop's own charge level.
        command: ["sh", "-c",
            "for b in /sys/class/power_supply/*; do " +
            "  [ -r \"$b/type\" ] || continue; " +
            "  [ \"$(cat \"$b/type\")\" = Battery ] || continue; " +
            "  [ \"$(cat \"$b/scope\" 2>/dev/null)\" = Device ] && continue; " +
            "  [ -r \"$b/capacity\" ] || continue; " +
            "  printf '%s|%s\\n' \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\" 2>/dev/null || echo Unknown)\"; " +
            "  exit 0; " +
            "done; echo NONE"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                if (line === "" || line === "NONE") {
                    root.available = false
                    return
                }
                const parts = line.split("|")
                const pct = parseInt(parts[0], 10)
                if (isNaN(pct)) {
                    root.available = false
                    return
                }
                root.available = true
                root.percent = Math.max(0, Math.min(100, pct))
                root.status = (parts[1] || "Unknown").trim() || "Unknown"
            }
        }
    }
}
