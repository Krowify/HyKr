// pactl-backed volume/mute state, polled -- matches the tool the rest of
// HyKr already shells out to (swaync's buttons-grid uses
// `pactl set-sink-mute @DEFAULT_SINK@ toggle`), rather than introducing
// wpctl as a second audio CLI dependency.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int volume: 0
    property bool muted: false

    // Set by VolumePanel from its own visibility. The dock bar shows only the
    // mute state; the numeric volume and the slider are panel-only. setVolume
    // updates root.volume locally, so the slider stays correct while open
    // without needing the poll to confirm it.
    property bool detailsWanted: false

    onDetailsWantedChanged: if (detailsWanted) volumeProc.running = true

    function refresh() {
        if (root.detailsWanted)
            volumeProc.running = true
        muteProc.running = true
    }

    function setVolume(pct) {
        const clamped = Math.max(0, Math.min(100, Math.round(pct)))
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", clamped + "%"])
        root.volume = clamped
    }

    function stepVolume(delta) {
        setVolume(root.volume + delta)
    }

    function toggleMute() {
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
        muteProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: volumeProc
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/(\d+)%/)
                if (m)
                    root.volume = parseInt(m[1])
            }
        }
    }

    Process {
        id: muteProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: root.muted = text.includes("yes")
        }
    }
}
