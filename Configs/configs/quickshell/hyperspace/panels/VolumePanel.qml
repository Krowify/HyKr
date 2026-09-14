// Drops from the dock's volume icon: level, a draggable bar, and mute.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    // Drive the pactl volume read from this panel's own visibility: it is
    // the only consumer of that value (the bar shows mute state alone), and
    // polling for it while the panel is closed was pure idle battery drain.
    // Component.onCompleted seeds it so the service agrees with reality
    // before the first toggle.
    onVisibleChanged: Services.AudioService.detailsWanted = root.visible
    Component.onCompleted: Services.AudioService.detailsWanted = root.visible

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
    implicitWidth: 230
    implicitHeight: 104
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyperspace-popup"

    anchors { top: true; right: true }
    margins {
        top: root.dock.barHeight + 6
        right: root.dock.panelMargin(root.implicitWidth, root.anchorScreen ? root.anchorScreen.width : 0)
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.colors.panel
        border.width: 1
        border.color: root.colors.hairline

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                spacing: 8
                Text {
                    text: "Volume"
                    color: root.colors.text
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.AudioService.muted ? "muted" : Services.AudioService.volume + "%"
                    color: Services.AudioService.muted ? root.colors.textDim : root.colors.accent
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            // Click or drag anywhere along the track to set the level. The
            // MouseArea is taller than the 5px track it sits on so the whole
            // row is grabbable -- a 5px-tall pointer target is not one.
            Item {
                width: parent.width
                height: 16

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 3
                    color: root.colors.mutedFill

                    Rectangle {
                        width: parent.width * (Services.AudioService.muted ? 0 : Services.AudioService.volume / 100)
                        height: parent.height
                        radius: 3
                        color: root.colors.accent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: mouse => {
                        if (pressed)
                            Services.AudioService.setVolume(mouse.x / width * 100);
                    }
                    onClicked: mouse => Services.AudioService.setVolume(mouse.x / width * 100)
                }
            }

            Rectangle {
                width: 84; height: 26; radius: 9
                color: Services.AudioService.muted ? root.colors.accent : root.colors.accentSoft
                border.width: 1
                border.color: root.colors.hairline

                Text {
                    anchors.centerIn: parent
                    text: Services.AudioService.muted ? "Unmute" : "Mute"
                    color: Services.AudioService.muted ? root.colors.bg : root.colors.text
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                }
                TapHandler { onTapped: Services.AudioService.toggleMute() }
            }
        }
    }
}
