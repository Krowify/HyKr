// CPU and RAM utilisation for the dock's left island (islands layout --
// the Default theme). A trimmed copy of ../../bar/services/
// SystemStatsService.qml: same /proc reads and maths, without the GPU and
// temperature probes this dock doesn't show. A fix to the parsing here
// belongs in both files -- the two configs can't share one copy (see
// ../../bar/README.md).
//
// Polls ONLY while `wanted` is true. shell.qml binds that to "the islands
// layout is on", so Sakura's flat bar pays nothing for this file.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool wanted: false

    // Percentages, 0-100; -1 until the first reading lands.
    property int cpu: -1
    property int memory: -1

    // /proc/stat is cumulative since boot, so usage is the delta between two
    // reads; the first poll only primes these.
    property real lastBusy: -1
    property real lastTotal: -1

    onWantedChanged: if (wanted) statsProc.running = true

    Timer {
        // Every 3s: enough to see load move, slow enough not to show up as
        // load itself on a laptop.
        interval: 3000
        running: root.wanted
        repeat: true
        onTriggered: statsProc.running = true
    }

    // The aggregate "cpu" row: busy = everything but idle + iowait.
    Process {
        id: statsProc
        command: ["sh", "-c",
            "read -r _ u n s i w q sq st _ < /proc/stat; " +
            "echo cpu $((u + n + s + q + sq + st)) $((i + w)); " +
            "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print \"mem\", t, a}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f[0] === "cpu" && f.length >= 3) {
                        const busy = Number(f[1]);
                        const total = busy + Number(f[2]);
                        if (root.lastTotal >= 0 && total > root.lastTotal) {
                            const pct = (busy - root.lastBusy) / (total - root.lastTotal) * 100;
                            root.cpu = Math.max(0, Math.min(100, Math.round(pct)));
                        }
                        root.lastBusy = busy;
                        root.lastTotal = total;
                    } else if (f[0] === "mem" && f.length >= 3) {
                        const totalKiB = Number(f[1]);
                        const availKiB = Number(f[2]);
                        if (totalKiB > 0)
                            root.memory = Math.round((totalKiB - availKiB) / totalKiB * 100);
                    }
                }
            }
        }
    }
}
