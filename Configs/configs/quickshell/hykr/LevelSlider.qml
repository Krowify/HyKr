// A level slider: icon, track, percentage. Drag or click the track; clicking
// the icon emits glyphClicked() (mute, in practice). Reports 0-100 while
// dragging (throttled) and on release, and ignores outside updates to `value`
// while held, so a status refresh can't yank the knob from under the pointer.
//
// Shared by the control centre and the quick panels (audio).
import QtQuick

Item {
    id: slider

    property string glyph: ""
    property int value: 0
    property bool muted: false
    property bool showPercent: true
    readonly property bool held: track.pressed

    signal moved(int value)
    signal glyphClicked()

    implicitHeight: 36

    Text {
        id: sliderGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        text: slider.glyph
        color: slider.muted ? Theme.textFaint : Theme.text
        font.family: Theme.font
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent
            onClicked: slider.glyphClicked()
        }
    }

    Rectangle {
        id: bar
        anchors.left: sliderGlyph.right
        anchors.leftMargin: 8
        anchors.right: slider.showPercent ? percent.left : parent.right
        anchors.rightMargin: slider.showPercent ? 10 : 4
        anchors.verticalCenter: parent.verticalCenter
        height: 10
        radius: 5
        color: Theme.hover

        Rectangle {
            width: Math.max(bar.height, bar.width * Math.max(0, Math.min(100, track.pressed ? track.dragValue : slider.value)) / 100)
            height: parent.height
            radius: parent.radius
            color: slider.muted ? Theme.textFaint : Theme.accent
        }

        MouseArea {
            id: track
            property int dragValue: 0
            anchors.fill: parent
            anchors.margins: -10
            function valueAt(x) {
                return Math.round(Math.max(0, Math.min(100, (x - 10) / bar.width * 100)));
            }
            onPressed: mouse => {
                track.dragValue = track.valueAt(mouse.x);
                slider.moved(track.dragValue);
            }
            onPositionChanged: mouse => {
                if (!track.pressed)
                    return;
                const v = track.valueAt(mouse.x);
                if (v !== track.dragValue) {
                    track.dragValue = v;
                    throttle.restart();
                }
            }
            onReleased: slider.moved(track.dragValue)
        }

        Timer {
            id: throttle
            interval: 80
            onTriggered: slider.moved(track.dragValue)
        }
    }

    Text {
        id: percent
        visible: slider.showPercent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: (track.pressed ? track.dragValue : slider.value) + "%"
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: Theme.fontSmall
    }
}
