import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services" as Services

PanelWindow {
    id: root

    property var anchorScreen
    property real barHeight: 34
    property real xOffset: 140

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 240
    implicitHeight: Math.min(280, 90 + (Services.BluetoothService.connectedDevices.length
        + Services.BluetoothService.pairedDevices.length) * 26)
    exclusionMode: "Ignore"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "laptop-popup"

    anchors { top: true; left: true }
    margins { top: root.barHeight + 6; left: root.xOffset }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#0d1a18"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Bluetooth"; color: "#eaf0ee"; font.pixelSize: 13; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
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

            Repeater {
                model: Services.BluetoothService.connectedDevices
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.name; color: "#eaf0ee"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: "connected"; color: "#4ade80"; font.pixelSize: 10 }
                }
            }

            Repeater {
                model: Services.BluetoothService.pairedDevices
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.name; color: "#c8d4d1"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
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

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height: 26; radius: 8
                color: "#c8102e"
                Text { anchors.centerIn: parent; text: "Open Bluetooth Manager"; color: "#eaf0ee"; font.pixelSize: 11 }
                TapHandler { onTapped: Services.BluetoothService.openManager() }
            }
        }
    }
}
