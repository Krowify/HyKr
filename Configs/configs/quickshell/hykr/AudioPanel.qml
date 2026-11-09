// Audio quick panel (the bar's volume icon, or the chevron on the control
// centre's volume slider): output and mic volume, which output / input to
// use, and a volume per app that's playing. Read by audio.sh every 1.5s
// while open; every change is one pactl command.
import Quickshell
import Quickshell.Io
import QtQuick

QuickPanel {
    id: root

    title: "Sound"
    surfaceName: "hykr-audio"

    property var sinks: []
    property var sources: []
    property var apps: []
    property var pending: ({ sinks: [], sources: [], apps: [] })

    readonly property var sink: root.pick(root.sinks)
    readonly property var source: root.pick(root.sources)

    function pick(list) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].isDefault)
                return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    function pactl(args) {
        Quickshell.execDetached(["pactl"].concat(args));
        refreshSoon.restart();
    }

    function deviceGlyph(d) {
        const n = (d.name + " " + d.description).toLowerCase();
        if (n.indexOf("bluez") >= 0 || n.indexOf("bluetooth") >= 0)
            return "\u{F02CB}";
        if (n.indexOf("hdmi") >= 0 || n.indexOf("displayport") >= 0)
            return "\u{F0379}";
        if (n.indexOf("headphone") >= 0 || n.indexOf("headset") >= 0)
            return "\u{F02CB}";
        if (n.indexOf("usb") >= 0)
            return "\u{F0553}";
        return "\u{F04C3}";
    }

    Timer {
        interval: 1500
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!stateProc.running) stateProc.running = true
    }

    Timer {
        id: refreshSoon
        interval: 250
        onTriggered: if (!stateProc.running) stateProc.running = true
    }

    Process {
        id: stateProc
        command: ["bash", Quickshell.shellPath("audio.sh")]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split("\t");
                if ((f[0] === "sink" || f[0] === "source") && f.length >= 6) {
                    root.pending[f[0] + "s"].push({
                        name: f[1], description: f[2], volume: parseInt(f[3]) || 0,
                        muted: f[4] === "true", isDefault: f[5] === "true"
                    });
                } else if (f[0] === "app" && f.length >= 5) {
                    root.pending.apps.push({
                        index: f[1], name: f[2], volume: parseInt(f[3]) || 0,
                        muted: f[4] === "true", media: f[5] || ""
                    });
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.sinks = root.pending.sinks;
            root.sources = root.pending.sources;
            root.apps = root.pending.apps;
            root.pending = { sinks: [], sources: [], apps: [] };
        }
    }

    // ---------------- output ----------------
    SectionLabel { text: "OUTPUT" }

    LevelSlider {
        width: parent.width
        visible: root.sink !== null
        glyph: root.sink && root.sink.muted ? "\u{F075F}" : "\u{F057E}"
        muted: root.sink ? root.sink.muted : false
        value: root.sink ? root.sink.volume : 0
        onMoved: v => root.pactl(["set-sink-volume", root.sink.name, v + "%"])
        onGlyphClicked: root.pactl(["set-sink-mute", root.sink.name, "toggle"])
    }

    Repeater {
        model: root.sinks.length > 1 ? root.sinks : []
        delegate: ListRow {
            required property var modelData
            glyph: root.deviceGlyph(modelData)
            title: modelData.description
            active: modelData.isDefault
            onClicked: root.pactl(["set-default-sink", modelData.name])
        }
    }

    Text {
        visible: root.sinks.length === 0
        text: "No output devices"
        color: Theme.textFaint
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }

    // ---------------- input ----------------
    SectionLabel {
        visible: root.sources.length > 0
        text: "INPUT"
    }

    LevelSlider {
        width: parent.width
        visible: root.source !== null
        glyph: root.source && root.source.muted ? "\u{F036D}" : "\u{F036C}"
        muted: root.source ? root.source.muted : false
        value: root.source ? root.source.volume : 0
        onMoved: v => root.pactl(["set-source-volume", root.source.name, v + "%"])
        onGlyphClicked: root.pactl(["set-source-mute", root.source.name, "toggle"])
    }

    Repeater {
        model: root.sources.length > 1 ? root.sources : []
        delegate: ListRow {
            required property var modelData
            glyph: "\u{F036C}"
            title: modelData.description
            active: modelData.isDefault
            onClicked: root.pactl(["set-default-source", modelData.name])
        }
    }

    // ---------------- apps ----------------
    SectionLabel {
        visible: root.apps.length > 0
        text: "APPS"
    }

    Repeater {
        model: root.apps
        delegate: Column {
            id: app
            required property var modelData
            width: parent.width
            spacing: 0

            Text {
                width: parent.width
                leftPadding: 4
                text: app.modelData.media.length > 0 ? app.modelData.name + " · " + app.modelData.media : app.modelData.name
                color: Theme.textDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
            LevelSlider {
                width: parent.width
                glyph: app.modelData.muted ? "\u{F075F}" : "\u{F0387}"
                muted: app.modelData.muted
                value: app.modelData.volume
                onMoved: v => root.pactl(["set-sink-input-volume", app.modelData.index, v + "%"])
                onGlyphClicked: root.pactl(["set-sink-input-mute", app.modelData.index, "toggle"])
            }
        }
    }
}
