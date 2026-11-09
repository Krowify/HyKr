// The search box at the top of every picker. Owns the list-navigation keys
// so each picker only has to say what Enter and Escape do.
//
//   Up / Down, Ctrl+K / Ctrl+J   move one row      -> navigate(-1 / +1)
//   Page Up / Page Down          move eight rows   -> navigate(-8 / +8)
//   Enter                        accepted()
//   Escape                       dismissed()
//   Delete at the end of the text deleteRequested() (nothing to delete
//                                 forward, so the picker can use it)
import QtQuick

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    property string glyph: "\u{F0349}"

    signal accepted()
    signal dismissed()
    signal navigate(int delta)
    signal deleteRequested()

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: 44
    radius: Theme.radiusSmall
    color: Theme.card
    border.width: 1
    border.color: input.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55) : Theme.border

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 16
    }

    TextInput {
        id: input
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        selectionColor: Theme.selected
        selectedTextColor: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 1
        clip: true

        Keys.onPressed: event => {
            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
            if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                root.navigate(1);
            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                root.navigate(-1);
            } else if (event.key === Qt.Key_PageDown) {
                root.navigate(8);
            } else if (event.key === Qt.Key_PageUp) {
                root.navigate(-8);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accepted();
            } else if (event.key === Qt.Key_Escape) {
                root.dismissed();
            } else if (event.key === Qt.Key_Delete && input.cursorPosition === input.text.length) {
                root.deleteRequested();
            } else {
                return;
            }
            event.accepted = true;
        }

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length === 0
            text: root.placeholder
            color: Theme.textFaint
            font: input.font
        }
    }
}
