// A round icon button: transparent until hovered, or filled with the accent
// (`accent: true`, e.g. play/pause). Shared by the control centre and the
// quick panels.
import QtQuick

Rectangle {
    id: btn

    property string glyph: ""
    property bool accent: false
    property int size: 38
    property int glyphSize: 16

    signal clicked()

    width: btn.size
    height: btn.size
    radius: btn.size / 2
    color: btn.accent ? Theme.accent : (btnMouse.containsMouse ? Theme.hover : "transparent")

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: btn.accent ? Theme.onAccent : Theme.text
        font.family: Theme.font
        font.pixelSize: btn.glyphSize
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btn.clicked()
    }
}
