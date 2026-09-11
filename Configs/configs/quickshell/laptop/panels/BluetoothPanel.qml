// Rewritten without QtQuick.Layouts (ColumnLayout/RowLayout) -- this
// file and NotificationCenterPanel.qml were the only two laptop-shell
// files using it, and both intermittently failed to load ("X is not a
// type") on real hardware while the plain-Column/Row panels never did.
// Whatever the root cause, plain Column/Row + anchors sidesteps it and
// matches VolumePanel/NetworkPanel's already-working approach.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    // Drive bluetoothctl device enumeration from this panel's own
    // visibility: it is the only consumer of that data, and polling for it
    // while the panel is closed was pure idle battery drain. Component.onCompleted
    // seeds it so the service agrees with reality before the first toggle.
    onVisibleChanged: Services.BluetoothService.detailsWanted = root.visible
    Component.onCompleted: Services.BluetoothService.detailsWanted = root.visible

    property var anchorScreen
    property real barHeight: 34
    property real rightOffset: 90

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 240
    implicitHeight: Math.min(280, 90 + (Services.BluetoothService.connectedDevices.length
        + Services.BluetoothService.pairedDevices.length) * 26)
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    anchors { top: true; right: true }
    margins { top: root.barHeight + 6; right: root.rightOffset }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#0d1a18"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        Row {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            Text { text: "Bluetooth"; color: "#eaf0ee"; font.pixelSize: 13; font.weight: Font.DemiBold }

            Item { width: parent.width - 74 - 52; height: 1 } // spacer

            Rectangle {
                width: 52; height: 20; radius: 8
                color: Services.BluetoothService.powered ? "#c8102e" : Qt.rgba(1, 1, 1, 0.08)
                Text {
                    anchors.centerIn: parent
                    text: Services.BluetoothService.powered ? "On" : "Off"
                    color: "#eaf0ee"
                    font.pixelSize: 10
                }
                TapHandler { onTapped: Services.BluetoothService.togglePower() }
            }
        }

        Column {
            anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 8; leftMargin: 14; rightMargin: 14 }
            spacing: 6

            Repeater {
                model: Services.BluetoothService.connectedDevices
                delegate: Row {
                    width: parent.width
                    Text { text: modelData.name; color: "#eaf0ee"; font.pixelSize: 12; width: parent.width - 70; elide: Text.ElideRight }
                    Text { text: "connected"; color: "#4ade80"; font.pixelSize: 10 }
                }
            }

            Repeater {
                model: Services.BluetoothService.pairedDevices
                delegate: Row {
                    width: parent.width
                    Text { text: modelData.name; color: "#c8d4d1"; font.pixelSize: 12; width: parent.width - 70; elide: Text.ElideRight }
                    Text { text: "paired"; color: "#6f8985"; font.pixelSize: 10 }
                }
            }

            Text {
                visible: Services.BluetoothService.connectedDevices.length === 0
                    && Services.BluetoothService.pairedDevices.length === 0
                text: "No devices"
                color: "#6f8985"
                font.pixelSize: 11
            }
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 14 }
            height: 26; radius: 8
            color: "#c8102e"
            Text { anchors.centerIn: parent; text: "Open Bluetooth Manager"; color: "#eaf0ee"; font.pixelSize: 11 }
            TapHandler { onTapped: Services.BluetoothService.openManager() }
        }
    }
}
