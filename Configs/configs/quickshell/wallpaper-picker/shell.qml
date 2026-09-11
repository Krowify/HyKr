// Grid-style wallpaper picker, replacing the previous dock-style scroller
// (adapted from 43PR/dotfiles' hyprquickpaper). Layout shape -- header with
// path/count, a card grid, an explicit Apply step -- follows mystiafin/shell's
// WallpaperPicker.qml/WallpaperCard.qml, but rewritten standalone: that
// project's version pulls in its own Theme/Typography/Icons/OverlayState
// singletons (~200 extra lines across 5 files) and renders the wallpaper
// itself via a custom GPU shader layer instead of a compositor daemon. This
// keeps a single self-contained file and defers entirely to commands.sh ->
// apply_wallpaper.sh (awww + pywal + kitty/starship/swaync/pywalfox), same
// as the picker it replaces.
//
// Selecting a card now stages a choice instead of applying immediately --
// double-click or the Apply button/Enter key commits it -- so an accidental
// click (or arrow-key drift) can't repaint the whole desktop's color
// pipeline before you meant it to.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland

PanelWindow {
    id: main

    // Same multi-monitor fix as the previous version: PanelWindow needs an
    // explicit screen or it can silently fail to attach to any output.
    screen: Quickshell.screens.find(s => Hyprland.monitorFor(s)?.id === Hyprland.focusedMonitor?.id) ?? Quickshell.screens[0]

    // No Theme.qml singleton -- config.json is the one source of color,
    // no external dependency. apply-theme.sh regenerates these fields
    // from the active theme's colors.json on every theme switch (same
    // as kitty/waybar/wofi), so the picker matches whatever's currently
    // themed instead of a fixed palette baked into this file.
    readonly property color colBgAlt: configs.bg
    readonly property color colSurface: configs.surface
    readonly property color colText: configs.text
    readonly property color colTextDim: configs.text_dim
    readonly property color colAccent: configs.border_color

    property int selectedIndex: -1

    // Hard pixel ceilings, not just a fraction of Screen.width/height --
    // on a 1920x1080 screen, Screen.height * 0.65 (702px) ran off the
    // bottom of the display in practice, so this caps at a size known to
    // fit comfortably rather than trusting the fraction alone.
    implicitWidth: Math.min(1300, Screen.width * 0.8)
    implicitHeight: Math.min(700, Screen.height * 0.75)
    color: "transparent"

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir])
        if (configs.wallpaper_path.length > 0)
            findProc.running = true
    }

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int columns
            property string border_color
            property string bg
            property string surface
            property string text
            property string text_dim
        }
    }

    // Same imperative trigger as before -- Process { running: <binding> }
    // produced no evidence of ever firing, so wallpaper_path changes are
    // handled explicitly instead of trusted as a live binding.
    Connections {
        target: configs
        function onWallpaper_pathChanged() {
            if (configs.wallpaper_path.length > 0)
                findProc.running = true
        }
    }

    // Qt.labs.folderlistmodel only lists a folder's immediate contents, not
    // subdirectories -- wallpapers are organized into subfolders (matching
    // hypr/wallpaper.sh's own recursive `find`), so this shells out the
    // same way that script does instead of silently limiting the grid to
    // whatever loose files sit at the top level.
    ListModel {
        id: folderModel
    }

    Process {
        id: findProc
        command: ["sh", "-c",
            `find -L "${configs.wallpaper_path}" -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \\) | sort`]
        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0)
                    return
                const parts = data.split("/")
                folderModel.append({ filePath: data, fileName: parts[parts.length - 1] })
            }
        }
    }

    function clampIndex(i) {
        return Math.max(0, Math.min(i, folderModel.count - 1))
    }

    function applySelection() {
        if (main.selectedIndex < 0 || main.selectedIndex >= folderModel.count)
            return
        const path = folderModel.get(main.selectedIndex).filePath
        Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), path])
        Qt.quit()
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: main.colBgAlt
        opacity: 0.88
        border.width: 2
        border.color: main.colAccent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Wallpapers"
                        color: main.colText
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: configs.wallpaper_path + " · " + folderModel.count + " images"
                        color: main.colTextDim
                        font.pixelSize: 11
                        font.family: "monospace"
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 26; height: 26; radius: 8
                    color: closeHover.hovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: main.colText
                        font.pixelSize: 12
                    }

                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: Qt.quit() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.15)
                clip: true

                GridView {
                    id: grid

                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.rightMargin: 22
                    cellWidth: width / Math.max(1, configs.columns)
                    cellHeight: cellWidth * 0.56
                    model: folderModel
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    focus: true

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AlwaysOn
                        width: 8

                        // QtQuick Controls docks an attached ScrollBar flush
                        // to the Flickable's own right edge, i.e. INSIDE the
                        // GridView's (already right-margined) bounds -- which
                        // put it right on top of the last column of cards.
                        // Push it out past that edge into the empty gutter
                        // the GridView's anchors.rightMargin reserved.
                        anchors.right: parent.right
                        anchors.rightMargin: -14
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: main.colAccent
                            opacity: vbar.pressed ? 1 : 0.7
                        }
                        background: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }
                    }

                    // Flickable's own wheel handling moves the content a
                    // small, fixed amount per notch -- fine for a couple of
                    // rows, tedious once there are a few hundred wallpapers.
                    // A velocity-based flick() didn't produce a felt change
                    // even at a high multiplier (Flickable's own deceleration/
                    // velocity clamping likely still won), so this jumps
                    // contentY directly instead -- a fixed, guaranteed pixel
                    // distance per notch with no physics in the way.
                    WheelHandler {
                        target: null
                        onWheel: (event) => {
                            // Temporary: three different speed tunings (flick
                            // x20, flick x50, direct contentY) all felt
                            // identical on real hardware, which means this
                            // handler may not be the thing actually moving
                            // the grid at all. This line proves whether it's
                            // even firing -- check launch.sh's terminal output
                            // while scrolling. Remove once confirmed.
                            console.log("[wallpaper-picker] wheel angleDelta.y =", event.angleDelta.y, "contentY before =", grid.contentY)
                            const maxY = Math.max(0, grid.contentHeight - grid.height)
                            grid.contentY = Math.max(0, Math.min(grid.contentY - event.angleDelta.y * 3, maxY))
                        }
                    }

                    delegate: Item {
                        id: card
                        required property int index
                        required property string filePath
                        required property string fileName

                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 14
                            clip: true
                            color: main.colSurface
                            border.width: main.selectedIndex === card.index ? 3 : 0
                            border.color: main.colAccent

                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: "file://" + configs.cache_path + card.fileName
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                smooth: true

                                Timer {
                                    id: retryTimer
                                    interval: 1000
                                    onTriggered: {
                                        const s = thumb.source
                                        thumb.source = ""
                                        thumb.source = s
                                    }
                                }
                                onStatusChanged: if (status === Image.Error) retryTimer.start()
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 22
                                color: Qt.rgba(0.067, 0.067, 0.106, 0.78)

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    text: card.fileName
                                    color: main.colText
                                    font.pixelSize: 9
                                    font.family: "monospace"
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                visible: main.selectedIndex === card.index
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 18; height: 18; radius: 6
                                color: main.colAccent

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: main.colBgAlt
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: main.selectedIndex = card.index }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onDoubleTapped: {
                                    main.selectedIndex = card.index
                                    main.applySelection()
                                }
                            }
                        }
                    }

                    Keys.onPressed: function(event) {
                        const cols = Math.max(1, configs.columns)
                        switch (event.key) {
                        case Qt.Key_Right:
                            main.selectedIndex = main.clampIndex((main.selectedIndex < 0 ? -1 : main.selectedIndex) + 1)
                            break
                        case Qt.Key_Left:
                            main.selectedIndex = main.clampIndex((main.selectedIndex < 0 ? 1 : main.selectedIndex) - 1)
                            break
                        case Qt.Key_Down:
                            main.selectedIndex = main.clampIndex((main.selectedIndex < 0 ? -cols : main.selectedIndex) + cols)
                            break
                        case Qt.Key_Up:
                            main.selectedIndex = main.clampIndex((main.selectedIndex < 0 ? cols : main.selectedIndex) - cols)
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            main.applySelection()
                            break
                        case Qt.Key_Escape:
                            Qt.quit()
                            break
                        default:
                            return
                        }
                        event.accepted = true
                    }
                }

                Column {
                    visible: folderModel.count === 0
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No wallpapers found"
                        color: main.colText
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: configs.wallpaper_path
                        color: main.colTextDim
                        font.pixelSize: 11
                        font.family: "monospace"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 78; height: 30; radius: 10
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: main.colTextDim
                        font.pixelSize: 11
                        font.family: "monospace"
                    }

                    TapHandler { onTapped: Qt.quit() }
                }

                Rectangle {
                    width: 78; height: 30; radius: 10
                    color: main.selectedIndex >= 0 ? main.colAccent : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: main.selectedIndex >= 0 ? main.colBgAlt : main.colTextDim
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: "monospace"
                    }

                    TapHandler {
                        enabled: main.selectedIndex >= 0
                        onTapped: main.applySelection()
                    }
                }
            }
        }
    }
}
