// Transient toast stack for new notifications -- separate from
// NotificationCenterPanel (the history/DND view opened from the dock's
// bell icon). Auto-dismisses each popup after a delay unless it's
// critical urgency.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./services" as Services

PanelWindow {
    id: root

    required property var modelData
    readonly property var targetScreen: modelData

    screen: targetScreen
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    // 34 (DockBar.barHeight) + 10 gap -- toasts sit below the top bar
    // now instead of flush against the screen edge.
    anchors { top: true; right: true }
    margins { top: 44; right: 14 }
    implicitWidth: 280
    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Services.NotificationService.popupModel

            delegate: Rectangle {
                id: toast
                width: column.width
                height: contentCol.implicitHeight + 20
                radius: 12
                color: "#0d1a18"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                readonly property color urgencyColor: urgency === "critical" ? "#f87171"
                    : urgency === "low" ? "#6f8985" : "#c8102e"

                Rectangle {
                    width: 3
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    radius: 2
                    color: toast.urgencyColor
                }

                Column {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 16
                    spacing: 2

                    Text { text: appName; color: "#8fa39f"; font.pixelSize: 10 }
                    Text { text: summary; color: "#eaf0ee"; font.pixelSize: 13; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                    Text {
                        visible: body.length > 0
                        text: body; color: "#c8d4d1"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap
                    }
                }

                TapHandler {
                    onTapped: Services.NotificationService.removePopupById(notificationId)
                }

                Timer {
                    running: true
                    interval: urgency === "critical" ? 12000 : 5000
                    onTriggered: Services.NotificationService.removePopupById(notificationId)
                }
            }
        }
    }
}
