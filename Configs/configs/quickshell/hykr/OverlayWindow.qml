// A full-screen overlay with one centred card: the frame every picker in this
// shell (launcher, clipboard, theme, wallpaper) sits in.
//
// - Opens on the monitor that has focus at the moment it opens (and stays
//   there while open, rather than following focus around).
// - Takes exclusive keyboard focus only while open, so typing goes straight
//   to the picker and nothing is grabbed while it is closed.
// - Click outside the card, or Escape (handled by each picker's key handler),
//   closes it.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property bool open: false
    property string surfaceName: "hykr"
    property int cardWidth: 640
    property int cardHeight: 460
    default property alias content: card.data

    signal opened()

    visible: root.open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: root.surfaceName

    function focusedScreen() {
        const mon = Hyprland.focusedMonitor;
        if (mon) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === mon.name)
                    return Quickshell.screens[i];
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    onOpenChanged: {
        if (root.open) {
            const s = root.focusedScreen();
            if (s)
                root.screen = s;
            root.opened();
        }
    }

    // Backdrop: dims the desktop and closes the overlay on a click outside
    // the card.
    Rectangle {
        anchors.fill: parent
        color: Theme.backdrop

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.cardWidth, parent.width - 48)
        height: Math.min(root.cardHeight, parent.height - 48)
        radius: Theme.radius
        color: Theme.panel
        border.width: 1
        border.color: Theme.border
        clip: true

        // Swallow clicks on the card itself so they don't reach the backdrop.
        MouseArea {
            anchors.fill: parent
        }
    }
}
