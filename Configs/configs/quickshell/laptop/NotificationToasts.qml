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

    // Bar bottom (34, plus Colors.barGap for a floating bar) + 10 -- toasts sit
    // below the top bar instead of flush against the screen edge, and line
    // up with a floating bar's inset right edge.
    anchors { top: true; right: true }
    margins { top: Colors.barBottom + 10; right: 14 + Colors.barGap }
    implicitWidth: 280
    // With no toasts queued the Column measures 0, which left this mapped
    // as a zero-height layer-shell surface the whole time the dock was up.
    // Hide the window outright when there's nothing to show, and keep the
    // implicit height off zero for the frame where it's still visible.
    visible: Services.NotificationService.popupModel.count > 0
    implicitHeight: Math.max(1, column.implicitHeight)

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
                // Same translucency as DockBar and the notification center
                // -- see NotificationCenterPanel.qml for why the alpha is in
                // the color rather than the opacity property. The urgency
                // stripe and the text below stay fully opaque so a toast is
                // still readable over a busy wallpaper.
                color: Colors.cardBg
                border.width: 1
                border.color: Colors.barBorder

                readonly property color urgencyColor: urgency === "critical" ? Colors.red
                    : urgency === "low" ? Colors.muted : Colors.accent

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

                    Text { text: appName; color: Colors.icon; font.pixelSize: 10 }
                    Text { text: summary; color: Colors.text; font.pixelSize: 13; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                    Text {
                        visible: body.length > 0
                        text: body; color: Colors.textSoft; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap
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
