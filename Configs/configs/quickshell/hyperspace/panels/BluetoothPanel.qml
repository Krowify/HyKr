// Drops from the dock's bluetooth icon: adapter toggle, the devices this
// machine knows about (tap a row to connect or disconnect it), and a way
// out to the full manager for anything else -- pairing a new device above
// all, which is blueman-manager's job, not this panel's.
//
// Written without QtQuick.Layouts (ColumnLayout/RowLayout) on purpose: in
// the Laptop shell this file and NotificationCenterPanel.qml were the only
// two using it, and both intermittently failed to load ("X is not a type")
// on real hardware while the plain-Column/Row panels never did. Whatever
// the root cause, plain Column/Row + anchors sidesteps it.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    // Drive the tighter bluetoothctl device enumeration from this panel's
    // own visibility -- see BluetoothService.qml, which polls slowly rather
    // than not at all while this is shut (the bar icon needs to know whether
    // anything is connected). Component.onCompleted seeds it so the service
    // agrees with reality before the first toggle.
    onVisibleChanged: Services.BluetoothService.detailsWanted = root.visible
    Component.onCompleted: Services.BluetoothService.detailsWanted = root.visible

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

    readonly property var connected: Services.BluetoothService.connectedDevices
    readonly property var paired: Services.BluetoothService.pairedDevices
    readonly property int deviceCount: connected.length + paired.length

    visible: false
    screen: anchorScreen
    color: "transparent"
    implicitWidth: 260
    // 104 covers the header, the "Open Bluetooth Manager" button and the
    // margins around them; each device row is 26 tall. Capped so a machine
    // that has paired a dozen things doesn't grow a panel taller than the
    // screen -- the list scrolls inside that cap instead.
    implicitHeight: Math.min(330, 104 + Math.max(1, root.deviceCount) * 26)
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
        clip: true

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
            height: 20

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: root.colors.text
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 52; height: 20; radius: 10
                color: Services.BluetoothService.powered ? root.colors.accent : root.colors.mutedFill

                Text {
                    anchors.centerIn: parent
                    text: Services.BluetoothService.powered ? "On" : "Off"
                    // Against a filled accent pill the label has to sit on
                    // the theme's background colour, not its foreground one:
                    // a wallpaper-derived accent is often light, and light
                    // text on it would vanish.
                    color: Services.BluetoothService.powered ? root.colors.bg : root.colors.textDim
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }
                TapHandler { onTapped: Services.BluetoothService.togglePower() }
            }
        }

        ListView {
            id: deviceList
            anchors {
                top: header.bottom; left: parent.left; right: parent.right; bottom: managerButton.top
                topMargin: 10; leftMargin: 14; rightMargin: 14; bottomMargin: 10
            }
            spacing: 4
            clip: true
            visible: root.deviceCount > 0

            // Connected first, then merely-paired. BluetoothService already
            // strips the connected ones out of its paired list, so nothing
            // appears twice.
            model: root.connected.concat(root.paired)

            delegate: Item {
                required property var modelData
                readonly property bool isConnected: root.connected.some(device => device.mac === modelData.mac)

                width: ListView.view.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 78
                    text: modelData.name
                    color: parent.isConnected ? root.colors.text : root.colors.textDim
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    // Reads as a label at rest and as the action it will
                    // perform under the pointer, so a tap is never a
                    // surprise -- there is no room here for a separate
                    // button per row.
                    text: rowHover.hovered ? (parent.isConnected ? "disconnect" : "connect") : (parent.isConnected ? "connected" : "paired")
                    color: parent.isConnected ? root.colors.good : root.colors.textDim
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }

                HoverHandler { id: rowHover }
                TapHandler {
                    onTapped: parent.isConnected ? Services.BluetoothService.disconnectDevice(modelData.mac) : Services.BluetoothService.connectDevice(modelData.mac)
                }
            }
        }

        Text {
            visible: root.deviceCount === 0
            anchors.centerIn: parent
            text: Services.BluetoothService.powered ? "No devices" : "Adapter off"
            color: root.colors.textDim
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
            id: managerButton
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 14 }
            height: 26; radius: 9
            color: managerHover.hovered ? root.colors.accent : root.colors.accentSoft
            border.width: 1
            border.color: root.colors.hairline

            Text {
                anchors.centerIn: parent
                text: "Open Bluetooth Manager"
                color: managerHover.hovered ? root.colors.bg : root.colors.text
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

            HoverHandler { id: managerHover }
            TapHandler { onTapped: Services.BluetoothService.openManager() }
        }
    }
}
