// CPU / RAM / temperature / GPU readings for the "stats" bar style (the
// Minimal theme), replacing the cpu, memory, temperature and custom/gpu
// modules of the waybar bar it used to run.
//
// Only this shell has it -- the Laptop dock shows none of these -- so unlike
// the other services here it has no twin in ../../laptop/services/.
//
// Polls ONLY while `wanted` is true, which shell.qml binds to "the stats bar
// is the one running". Every other bar style leaves it false, so the
// Hyperspace notch, the islands and the pill pay nothing for this file
// existing. Same Process + Timer polling the rest of these services use.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool wanted: false

    // Percentages, 0-100. -1 until the first reading lands, so the bar can
    // tell "not measured yet" from a real 0%.
    property int cpu: -1
    property int memory: -1
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0

    // Degrees C from thermal_zone0, the zone waybar's temperature module was
    // pointed at. -1 when that zone doesn't exist.
    property int temperature: -1
    readonly property bool temperatureAvailable: root.temperature >= 0
    // waybar's critical-threshold for the same module.
    readonly property int temperatureCritical: 80
    readonly property bool temperatureHigh: root.temperature >= root.temperatureCritical

    property int gpu: -1
    // False until a probe actually returns a number -- a machine with no
    // readable GPU utilisation hides the module rather than showing "GPU -1%".
    readonly property bool gpuAvailable: root.gpu >= 0

    // /proc/stat is cumulative since boot, so usage is the delta between two
    // reads. Kept here between polls; the first poll only primes them.
    property real lastBusy: -1
    property real lastTotal: -1

    onWantedChanged: if (wanted) root.refresh()

    function refresh() {
        statsProc.running = true;
        gpuProc.running = true;
    }

    Timer {
        // waybar's interval for the same modules.
        interval: 2000
        running: root.wanted
        repeat: true
        onTriggered: statsProc.running = true
    }

    Timer {
        // Slower than the rest: on an NVIDIA machine the probe below is
        // nvidia-smi or nvtop, each a full process start, and GPU load is the
        // least jumpy of the four readings anyway.
        interval: 4000
        running: root.wanted
        repeat: true
        onTriggered: gpuProc.running = true
    }

    // One process for the three cheap readings, all plain file reads. The
    // CPU line is the aggregate "cpu" row: busy = everything but idle+iowait.
    Process {
        id: statsProc
        command: ["sh", "-c",
            "read -r _ u n s i w q sq st _ < /proc/stat; " +
            "echo cpu $((u + n + s + q + sq + st)) $((i + w)); " +
            "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print \"mem\", t, a}' /proc/meminfo; " +
            "t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) && echo temp \"$t\""]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f[0] === "cpu" && f.length >= 3) {
                        const busy = Number(f[1]);
                        const idle = Number(f[2]);
                        const total = busy + idle;
                        if (root.lastTotal >= 0 && total > root.lastTotal) {
                            const pct = (busy - root.lastBusy) / (total - root.lastTotal) * 100;
                            root.cpu = Math.max(0, Math.min(100, Math.round(pct)));
                        }
                        root.lastBusy = busy;
                        root.lastTotal = total;
                    } else if (f[0] === "mem" && f.length >= 3) {
                        const totalKiB = Number(f[1]);
                        const availKiB = Number(f[2]);
                        if (totalKiB > 0) {
                            root.memory = Math.round((totalKiB - availKiB) / totalKiB * 100);
                            root.memoryUsedGiB = (totalKiB - availKiB) / 1048576;
                            root.memoryTotalGiB = totalKiB / 1048576;
                        }
                    } else if (f[0] === "temp" && f.length >= 2) {
                        const milli = Number(f[1]);
                        if (isFinite(milli))
                            root.temperature = Math.round(milli / 1000);
                    }
                }
            }
        }
    }

    // GPU utilisation, cheapest source first: amdgpu (and some Intel) expose
    // it as a plain sysfs file; NVIDIA needs nvidia-smi; nvtop -s is the
    // GPU-agnostic fallback the old waybar module (waybar/scripts/
    // gpu_usage.sh) used. Prints nothing when none of them work, which leaves
    // gpu at -1 and the module hidden.
    Process {
        id: gpuProc
        command: ["sh", "-c",
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do " +
            "  [ -r \"$f\" ] && { cat \"$f\"; exit 0; }; " +
            "done; " +
            "if command -v nvidia-smi >/dev/null 2>&1; then " +
            "  nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1; exit 0; " +
            "fi; " +
            "if command -v nvtop >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then " +
            "  nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' 2>/dev/null | tr -d '%'; " +
            "fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                root.gpu = isFinite(n) ? Math.max(0, Math.min(100, n)) : -1;
            }
        }
    }
}
