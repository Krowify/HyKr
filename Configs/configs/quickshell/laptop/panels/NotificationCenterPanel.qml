import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 300
    implicitHeight: 420
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    anchors { top: true; bottom: true; left: true }
    margins { left: 58; top: 14; bottom: 14 }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#0d1a18"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Notifications"; color: "#eaf0ee"; font.pixelSize: 14; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 66; height: 22; radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Text { anchors.centerIn: parent; text: "Clear all"; color: "#c8d4d1"; font.pixelSize: 10 }
                    TapHandler { onTapped: Services.NotificationService.clear() }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Do Not Disturb"; color: "#c8d4d1"; font.pixelSize: 11.5; Layout.fillWidth: true }
                Rectangle {
                    width: 34; height: 18; radius: 10
                    color: Services.NotificationService.doNotDisturb ? "#c8102e" : Qt.rgba(1, 1, 1, 0.12)
                    Rectangle {
                        width: 14; height: 14; radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        x: Services.NotificationService.doNotDisturb ? parent.width - width - 2 : 2
                        color: "#0d1a18"
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                    TapHandler {
                        onTapped: Services.NotificationService.doNotDisturb = !Services.NotificationService.doNotDisturb
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                model: Services.NotificationService.historyModel

                delegate: Rectangle {
                    width: ListView.view.width
                    height: contentCol.implicitHeight + 20
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)

                    Column {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Row {
                            spacing: 8
                            width: parent.width
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: urgency === "critical" ? "#f87171"
                                    : urgency === "low" ? "#6f8985" : "#c8102e"
                            }
                            Text { text: appName; color: "#8fa39f"; font.pixelSize: 10 }
                        }
                        Text { text: summary; color: "#eaf0ee"; font.pixelSize: 12; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                        Text {
                            visible: body.length > 0
                            text: body; color: "#c8d4d1"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap
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
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: "#6f8985"
                font.pixelSize: 12
            }
        }
    }
}
