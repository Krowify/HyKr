// HyKr quick-settings panel (Super+M), Quickshell version — replaces the
// earlier Eww panel, mirroring end-4/dots-hyprland's own move off Eww.
//
// UNVERIFIED: no `quickshell` binary was available to actually run this
// against, so treat the Process/polling wiring below as best-effort against
// Quickshell's documented API, not confirmed-working. The layout (PanelWindow +
// QtQuick.Controls/Layouts) is standard Qt and should be solid; the Process
// blocks are the most likely place something needs fixing.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    PanelWindow {
        id: panel
        anchors {
            top: true
            right: true
        }
        margins {
            top: 40
        }
        implicitWidth: 320
        implicitHeight: 260
        color: "#1e1e2e"

        property int volume: 50
        property int brightness: 50
        property bool wifiOn: false
        property bool btOn: false
        property bool nightLightOn: false

        // --- Polling (every 2-3s) ---------------------------------------
        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                volumeProc.running = true
                nightLightProc.running = true
            }
        }
        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: {
                brightnessProc.running = true
                wifiProc.running = true
                btProc.running = true
            }
        }

        Process {
            id: volumeProc
            command: ["pamixer", "--get-volume"]
            stdout: SplitParser { onRead: (data) => panel.volume = parseInt(data.trim()) || 0 }
        }
        Process {
            id: brightnessProc
            command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
            stdout: SplitParser { onRead: (data) => panel.brightness = parseInt(data.trim()) || 0 }
        }
        Process {
            id: wifiProc
            command: ["bash", "-c", "nmcli radio wifi | grep -q enabled && echo 1 || echo 0"]
            stdout: SplitParser { onRead: (data) => panel.wifiOn = data.trim() === "1" }
        }
        Process {
            id: btProc
            command: ["bash", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0"]
            stdout: SplitParser { onRead: (data) => panel.btOn = data.trim() === "1" }
        }
        Process {
            id: nightLightProc
            command: ["bash", "-c", "pgrep -x hyprsunset >/dev/null && echo 1 || echo 0"]
            stdout: SplitParser { onRead: (data) => panel.nightLightOn = data.trim() === "1" }
        }

        // --- Actions (one-shot on click/change) --------------------------
        Process { id: wifiToggle; command: ["bash", "-c", "nmcli radio wifi $(nmcli radio wifi | grep -q enabled && echo off || echo on)"] }
        Process { id: btToggle; command: ["bash", "-c", "bluetoothctl power $(bluetoothctl show | grep -q 'Powered: yes' && echo off || echo on)"] }
        Process { id: nightLightToggle; command: ["bash", "-c", "pkill hyprsunset || hyprsunset"] }
        Process { id: setVolume; command: ["pamixer", "--set-volume", "0"] }
        Process { id: setBrightness; command: ["brightnessctl", "set", "50%"] }
        Process { id: lockCmd; command: ["hyprlock"] }
        Process { id: logoutCmd; command: ["wlogout"] }
        Process { id: themeCmd; command: ["nwg-look"] }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Button {
                    text: "󰖩 Wi-Fi"
                    highlighted: panel.wifiOn
                    onClicked: wifiToggle.running = true
                }
                Button {
                    text: "󰂯 Bluetooth"
                    highlighted: panel.btOn
                    onClicked: btToggle.running = true
                }
                Button {
                    text: "󰛨 Night Light"
                    highlighted: panel.nightLightOn
                    onClicked: nightLightToggle.running = true
                }
            }

            RowLayout {
                spacing: 8
                Text { text: "󰕾"; color: "#df7a8c" }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: panel.volume
                    onMoved: {
                        setVolume.command = ["pamixer", "--set-volume", Math.round(value).toString()]
                        setVolume.running = true
                    }
                }
            }
            RowLayout {
                spacing: 8
                Text { text: "󰃟"; color: "#df7a8c" }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: panel.brightness
                    onMoved: {
                        setBrightness.command = ["brightnessctl", "set", Math.round(value) + "%"]
                        setBrightness.running = true
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Button { text: "󰌾"; onClicked: lockCmd.running = true }
                Button { text: "⏻"; onClicked: logoutCmd.running = true }
                Button { text: "󰒓"; onClicked: themeCmd.running = true }
            }
        }
    }
}
