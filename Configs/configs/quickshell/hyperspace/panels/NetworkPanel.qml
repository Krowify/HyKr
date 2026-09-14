// Drops from the dock's network icon: what you're connected to, and
// ProtonVPN. Right-clicking the icon bypasses this entirely and launches
// NetworkManager (see DockBar.qml) -- same split as the Laptop dock.
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Services

PanelWindow {
    id: root

    // Drive the protonvpn-cli status poll from this panel's own visibility:
    // it is the only consumer of that data, and polling for it while the
    // panel is closed was pure idle battery drain -- protonvpn-cli spawns a
    // Python interpreter per call. Component.onCompleted seeds it so the
    // service agrees with reality before the first toggle.
    onVisibleChanged: Services.NetworkService.detailsWanted = root.visible
    Component.onCompleted: Services.NetworkService.detailsWanted = root.visible

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
    implicitWidth: 250
    implicitHeight: 164
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
            spacing: 8

            // ---- what the machine is actually on ----
            Row {
                spacing: 7
                width: parent.width

                Rectangle {
                    width: 7; height: 7; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Services.NetworkService.connectionType === "disconnected" ? root.colors.bad : root.colors.good
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 14
                    text: Services.NetworkService.connectionType === "disconnected" ? "Offline" : (Services.NetworkService.connectionName || Services.NetworkService.connectionType)
                    color: root.colors.text
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.colors.hairline }

            // ---- ProtonVPN ----
            Text {
                text: "ProtonVPN"
                color: root.colors.text
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.DemiBold
            }

            Row {
                visible: Services.NetworkService.vpnAvailable
                spacing: 7
                Rectangle {
                    width: 7; height: 7; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Services.NetworkService.vpnConnected ? root.colors.good : root.colors.muted
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.NetworkService.vpnConnected ? ("Connected - " + (Services.NetworkService.vpnServer || "unknown server")) : "Not connected"
                    color: root.colors.textDim
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            Text {
                visible: !Services.NetworkService.vpnAvailable && !Services.NetworkService.vpnGuiAvailable
                text: "ProtonVPN not installed"
                color: root.colors.textDim
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }

            // With protonvpn-cli present, connect/disconnect happens right
            // here; the GUI button below still opens the app for anything
            // this panel doesn't cover (picking a specific country, settings).
            Row {
                spacing: 8
                width: parent.width

                Rectangle {
                    width: Services.NetworkService.vpnAvailable ? (parent.width - 8) / 2 : parent.width
                    height: 27; radius: 9
                    visible: Services.NetworkService.vpnAvailable
                    color: quickHover.hovered ? root.colors.accent : root.colors.accentSoft
                    border.width: 1
                    border.color: root.colors.hairline

                    Text {
                        anchors.centerIn: parent
                        text: Services.NetworkService.vpnConnected ? "Disconnect" : "Quick Connect"
                        color: quickHover.hovered ? root.colors.bg : root.colors.text
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    HoverHandler { id: quickHover }
                    TapHandler {
                        onTapped: Services.NetworkService.vpnConnected ? Services.NetworkService.vpnDisconnect() : Services.NetworkService.vpnConnect()
                    }
                }

                // protonvpn-cli isn't installed everywhere this theme runs --
                // when only the GUI client is present this is the whole
                // control, stretched to the full width, rather than a dead
                // "Quick Connect" that shells out to a CLI that isn't there.
                Rectangle {
                    width: Services.NetworkService.vpnAvailable ? (parent.width - 8) / 2 : parent.width
                    height: 27; radius: 9
                    visible: Services.NetworkService.vpnGuiAvailable
                    color: guiHover.hovered ? root.colors.accent : root.colors.accentSoft
                    border.width: 1
                    border.color: root.colors.hairline

                    Text {
                        anchors.centerIn: parent
                        text: "Open App"
                        color: guiHover.hovered ? root.colors.bg : root.colors.text
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    HoverHandler { id: guiHover }
                    TapHandler { onTapped: Services.NetworkService.openVpnApp() }
                }
            }

            Text {
                text: "Right-click the network icon for Network Manager"
                color: root.colors.textDim
                opacity: 0.8
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}
