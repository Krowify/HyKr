// Transient toast stack for new notifications -- separate from
// NotificationCenterPanel (the history/DND view opened from the dock's bell
// icon). Auto-dismisses each popup after a delay unless it's critical
// urgency. Adapted from ../laptop/NotificationToasts.qml, with every colour
// coming from Colors.qml (i.e. from the wallpaper) instead of being fixed.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "./services" as Services

PanelWindow {
    id: root

    required property var modelData
    readonly property var targetScreen: modelData

    screen: targetScreen
    color: "transparent"
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyperspace-popup"

    // Hangs from just under the right island, lined up with it.
    anchors { top: true; right: true }
    margins { top: DockState.barHeight + 6; right: DockState.islandMargin }
    implicitWidth: 300
    // With no toasts queued the Column measures 0, which would leave this
    // mapped as a zero-height layer-shell surface the whole time the dock is
    // up. Hide the window outright when there's nothing to show, and keep
    // the implicit height off zero for the frame where it's still visible.
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
                radius: 14
                // Same translucency as the dock's islands -- alpha lives in
                // the colour, NOT in an Item's `opacity` property, which
                // cascades to children in Qt Quick and would fade the text
                // along with the background. The theme's hyprland.lua.tpl
                // blurs this namespace with ignore_alpha = 0.2, which 0.55
                // clears, so a toast picks up the same blur as the bar.
                color: Colors.island
                border.width: 1
                border.color: Colors.hairline

                readonly property color urgencyColor: urgency === "critical" ? Colors.bad : urgency === "low" ? Colors.muted : Colors.accent

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
                    spacing: 3

                    Text {
                        text: appName
                        color: Colors.textDim
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: summary
                        color: Colors.text
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.DemiBold
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        visible: body.length > 0
                        text: body
                        color: Colors.textDim
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        width: parent.width
                        wrapMode: Text.WordWrap
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
