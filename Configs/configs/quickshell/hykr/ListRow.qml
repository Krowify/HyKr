// One row in a quick panel's list: an audio device, a Bluetooth device, a
// Wi-Fi network. Icon, title, a detail line, and on the right either a
// check (`active`), a status word (`trailing`), or a spinner-ish "…" while
// `busy`. An optional secondary icon button (forget a device, ...) sits at
// the far right.
import QtQuick

Rectangle {
    id: row

    property string glyph: ""
    property string title: ""
    property string detail: ""
    property bool active: false
    property string trailing: ""
    property bool busy: false
    property string secondaryGlyph: ""

    signal clicked()
    signal secondaryClicked()

    width: parent ? parent.width : 300
    height: 48
    radius: Theme.radiusSmall
    color: row.active ? Theme.selected : (mouse.containsMouse ? Theme.hover : "transparent")

    Rectangle {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: row.active ? Theme.accent : Theme.card

        Text {
            anchors.centerIn: parent
            text: row.glyph
            color: row.active ? Theme.onAccent : Theme.text
            font.family: Theme.font
            font.pixelSize: 15
        }
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: right.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: row.active
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: row.detail
            color: Theme.textDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.clicked()
    }

    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: row.busy ? "…" : (row.trailing.length > 0 ? row.trailing : (row.active ? "\u{F012C}" : ""))
            color: row.active ? Theme.accent : Theme.textDim
            font.family: Theme.font
            font.pixelSize: row.trailing.length > 0 && !row.busy ? Theme.fontSmall : 15
        }

        RoundButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.secondaryGlyph.length > 0
            size: 30
            glyphSize: 13
            glyph: row.secondaryGlyph
            onClicked: row.secondaryClicked()
        }
    }
}
