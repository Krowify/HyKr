// A small heading between groups in a quick panel ("OUTPUT", "DEVICES").
import QtQuick

Text {
    width: parent ? parent.width : 0
    topPadding: 6
    color: Theme.textFaint
    font.family: Theme.font
    font.pixelSize: Theme.fontSmall - 1
    font.bold: true
    font.letterSpacing: 1
}
