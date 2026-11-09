// The thumbnail grid both pickers use (wallpapers, themes).
//
// model: array of { path, title, subtitle, badge }. `path` is the image the
// card previews; thumbs[path] is its cached thumbnail from thumbs.sh --
// undefined while it is still being made (a placeholder shows), "" when there
// is none (no ImageMagick, or the image couldn't be read; the image itself is
// then loaded at a reduced size instead).
//
// Hovering a card selects it; a click selects it, a double-click activates
// it. Enter in the picker's search box activates the selection too.
import QtQuick

GridView {
    id: root

    property var thumbs: ({})
    property int selected: 0
    property int columns: 4

    signal activated(int index)

    function keepVisible() {
        root.positionViewAtIndex(root.selected, GridView.Contain);
    }

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    cellWidth: Math.floor(root.width / root.columns)
    cellHeight: Math.round((root.cellWidth - 12) * 9 / 16) + 46
    currentIndex: root.selected

    delegate: Item {
        id: cell
        required property var modelData
        required property int index

        readonly property var thumb: root.thumbs[cell.modelData.path]
        readonly property bool isSelected: cell.index === root.selected

        width: root.cellWidth
        height: root.cellHeight

        Rectangle {
            id: frame
            anchors.fill: parent
            anchors.margins: 6
            radius: Theme.radiusSmall
            color: cell.isSelected ? Theme.selected : (mouse.containsMouse ? Theme.hover : "transparent")
            border.width: cell.isSelected ? 2 : 0
            border.color: Theme.accent

            Rectangle {
                id: imageBox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                height: Math.round(width * 9 / 16)
                radius: Theme.radiusSmall - 2
                color: Theme.card
                clip: true

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    // A thumbnail when there is one; otherwise the image itself,
                    // decoded at card size rather than full resolution.
                    source: cell.thumb === undefined ? "" : Theme.fileUrl(cell.thumb || cell.modelData.path)
                    sourceSize.width: cell.thumb ? 0 : 480
                }

                Text {
                    anchors.centerIn: parent
                    visible: cell.thumb === undefined
                    text: "\u{F0976}"
                    color: Theme.textFaint
                    font.family: Theme.font
                    font.pixelSize: 22
                }

                Rectangle {
                    visible: (cell.modelData.badge || "").length > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: badgeText.implicitWidth + 12
                    height: 20
                    radius: 10
                    color: Theme.accent

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: cell.modelData.badge || ""
                        color: Theme.onAccent
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            Column {
                anchors.top: imageBox.bottom
                anchors.topMargin: 5
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 0

                Text {
                    width: parent.width
                    text: cell.modelData.title || ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall + 1
                    elide: Text.ElideMiddle
                }
                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: cell.modelData.subtitle || ""
                    color: Theme.textFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSmall - 1
                    elide: Text.ElideMiddle
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selected = cell.index
                onClicked: root.selected = cell.index
                onDoubleClicked: root.activated(cell.index)
            }
        }
    }
}
