// An on/off switch in the theme's accent (Wi-Fi radio, Bluetooth power).
import QtQuick

Rectangle {
    id: sw

    property bool checked: false
    signal toggled()

    width: 42
    height: 24
    radius: 12
    color: sw.checked ? Theme.accent : Theme.hover

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        color: sw.checked ? Theme.onAccent : Theme.textDim
        Behavior on x { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: sw.toggled()
    }
}
