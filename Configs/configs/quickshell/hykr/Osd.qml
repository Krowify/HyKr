// On-screen display for the volume, mic and brightness keys: a small pill
// near the bottom of the focused screen with an icon, a level bar and the
// percentage, gone 1.5s after the last change.
//
// Driven by hypr/osd.sh, which the keys run: it makes the change (the same
// pamixer / brightnessctl commands the keys always ran), reads the new level
// and calls show() over IPC -- so the pill appears the instant the key is
// pressed, with no polling. Click-through (an empty input region), so it never
// gets in the way of the window under it.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property string kind: "volume"
    property int value: 0
    property bool muted: false
    property bool shown: false

    function show(kind, value, muted) {
        root.kind = kind;
        root.value = Math.max(0, Math.min(100, value));
        root.muted = muted;
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === mon.name)
                    root.screen = Quickshell.screens[i];
            }
        }
        root.shown = true;
        hide.restart();
    }

    readonly property string glyph: {
        if (root.kind === "brightness")
            return "\u{F00DF}";
        if (root.kind === "mic")
            return root.muted ? "\u{F036D}" : "\u{F036C}";
        if (root.muted || root.value === 0)
            return "\u{F075F}";
        return root.value < 34 ? "\u{F057F}" : (root.value < 67 ? "\u{F0580}" : "\u{F057E}");
    }

    visible: root.shown
    color: "transparent"
    anchors.bottom: true
    margins.bottom: 90
    implicitWidth: 300
    implicitHeight: 52
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "hykr-osd"

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        Text {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: root.glyph
            color: root.muted ? Theme.textFaint : Theme.text
            font.family: Theme.font
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: track
            anchors.left: icon.right
            anchors.leftMargin: 14
            anchors.right: label.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 8
            radius: 4
            color: Theme.hover

            Rectangle {
                width: track.width * root.value / 100
                height: parent.height
                radius: parent.radius
                color: root.muted ? Theme.textFaint : Theme.accent
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }

        Text {
            id: label
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "Muted" : root.value + "%"
            color: Theme.textDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
        }
    }
}
