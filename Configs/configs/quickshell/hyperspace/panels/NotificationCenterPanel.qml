// Drops from the dock's bell icon: notification history, Do Not Disturb,
// clear-all. This shell carries its own notification daemon (see
// services/NotificationService.qml), so nothing external -- swaync, dunst,
// mako -- runs under the Hyperspace theme.
//
// Written without QtQuick.Layouts -- see BluetoothPanel.qml's header.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen

    // `colors` and `dock` are the Colors.qml / DockState.qml singletons,
    // handed in by shell.qml rather than referenced by name here. Both live
    // in the config ROOT, one directory up: a file in panels/ reaches
    // anything outside its own directory through an explicit import (which
    // is exactly what `import "../services"` above is doing for the
    // services), so injecting the two the panels need keeps this file from
    // depending on a root-level singleton resolving unqualified from a
    // subdirectory. shell.qml sits next to both and can name them directly.
    required property var colors
    required property var dock

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 320
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyperspace-popup"

    // The one panel that doesn't hang under its icon: it's a full-height
    // column, so it stays pinned to the right edge (where the bell is
    // anyway, at the end of the right island) rather than being centred on a
    // 20px glyph.
    anchors { top: true; bottom: true; right: true }
    margins { right: root.dock.islandMargin; top: root.dock.barHeight + 6; bottom: 14 }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: root.colors.panel
        border.width: 1
        border.color: root.colors.hairline
        clip: true

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            height: 22

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: root.colors.text
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 68; height: 22; radius: 9
                visible: Services.NotificationService.historyCount > 0
                color: clearHover.containsMouse ? root.colors.accent : root.colors.mutedFill

                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: clearHover.containsMouse ? root.colors.bg : root.colors.textDim
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
                // MouseArea rather than a pointer handler -- see
                // NetworkPanel.qml for what that cost.
                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Services.NotificationService.clear()
                }
            }
        }

        Item {
            id: dndRow
            anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 14; rightMargin: 14 }
            height: 20

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Do Not Disturb"
                color: root.colors.textDim
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 19; radius: 10
                color: Services.NotificationService.doNotDisturb ? root.colors.accent : root.colors.mutedFill

                Rectangle {
                    width: 15; height: 15; radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    x: Services.NotificationService.doNotDisturb ? parent.width - width - 2 : 2
                    // The knob sits on the theme's background colour so it
                    // stays visible whether the track behind it is the
                    // (possibly light) accent or a dim fill.
                    color: root.colors.bg
                    Behavior on x { NumberAnimation { duration: 120 } }
                }
                TapHandler {
                    onTapped: Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb
                }
            }
        }

        ListView {
            anchors {
                top: dndRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                topMargin: 12; leftMargin: 14; rightMargin: 14; bottomMargin: 14
            }
            spacing: 8
            clip: true
            model: Services.NotificationService.historyModel

            delegate: Rectangle {
                width: ListView.view.width
                height: contentCol.implicitHeight + 20
                radius: 12
                color: root.colors.mutedFill
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                Column {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 3

                    Row {
                        spacing: 8
                        width: parent.width
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: urgency === "critical" ? root.colors.bad : urgency === "low" ? root.colors.muted : root.colors.accent
                        }
                        Text {
                            text: appName
                            color: root.colors.textDim
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                    Text {
                        text: summary
                        color: root.colors.text
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.DemiBold
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        visible: body.length > 0
                        text: body
                        color: root.colors.textDim
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: Services.NotificationService.dismiss(notificationId)
                }
            }
        }

        Text {
            visible: Services.NotificationService.historyCount === 0
            anchors.centerIn: parent
            text: "No notifications"
            color: root.colors.textDim
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
        }
    }
}
