// The frame for the audio / Bluetooth / network quick panels: the same
// top-right spot, card and colours as the control centre, a title row with a
// slot for header controls (a switch, a rescan button), and a body.
//
// Closed by a click anywhere else (Hyprland focus grab) or Escape. `back()`
// is emitted by the title's back arrow, shown when the panel was opened from
// the control centre, so you can go back to it.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property bool open: false
    property string title: ""
    property bool showBack: false
    property string surfaceName: "hykr-panel"
    property int panelWidth: 380
    property int maxBodyHeight: 520
    default property alias body: content.data
    property alias headerItems: headerRow.data

    signal back()

    visible: root.open
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 8; right: 8 }
    implicitWidth: root.panelWidth
    // 16 top margin + header + 10 gap + body (scrolls past maxBodyHeight) + 16 bottom.
    implicitHeight: 16 + header.height + 10 + Math.min(content.implicitHeight, root.maxBodyHeight) + 16
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: root.surfaceName

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.open = false
    }

    onOpenChanged: if (root.open) keys.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.open = false
        }

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 34

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                RoundButton {
                    visible: root.showBack
                    size: 30
                    glyphSize: 14
                    glyph: "\u{F004D}"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.back()
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            Row {
                id: headerRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
            }
        }

        Flickable {
            anchors.top: header.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 8
            }
        }
    }
}
