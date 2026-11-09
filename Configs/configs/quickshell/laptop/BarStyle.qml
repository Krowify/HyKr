// Per-theme bar shape for `quickshell -c laptop`.
//
// Two themes run this shell -- Laptop and Blackturq -- and they want
// different bars from it: Laptop a flat strip flush with the top edge,
// Blackturq a floating, rounded bar with a grey outline. Rather than fork
// ~700 lines of QML for that, the shape is read from style.json in this
// directory, which apply-theme.sh writes on every theme apply from the
// active theme's theme.json "quickshell" block (everything except
// "config"), e.g.
//
//   "quickshell": {
//     "config": "laptop",
//     "rounded": true,
//     "radius": 10,
//     "gap": 8,
//     "border": "#6b6f75",
//     "clockSize": 14,
//     "dateSize": 14
//   }
//
// A theme that says nothing (Laptop) gets an empty file, i.e. every default
// below -- which is exactly the bar this shell has always drawn. Not
// committed to the repo: it's generated, like colors.json's live contents.
//
// FileView watches it, so a hand edit shows up live; panel positions follow
// because shell.qml binds them to barBottom / sideGap.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The bar itself, excluding any gap around it.
    readonly property int barHeight: 34

    // Floating + rounded, or flat and flush with the screen edges.
    readonly property bool rounded: adapter.rounded === true

    // How far a rounded bar floats in from the top, left and right edges.
    // Zero when flat: a square bar runs edge to edge as it always has.
    readonly property int gap: root.rounded ? Math.max(0, Math.min(40, Number(adapter.gap) || 0)) : 0
    readonly property int sideGap: root.gap

    readonly property int radius: root.rounded ? Math.max(0, Math.min(root.barHeight / 2, Number(adapter.radius) || 0)) : 0

    // The outline. An explicit theme colour when given; otherwise the faint
    // white hairline the flat bar has always had.
    readonly property bool hasBorderColour: typeof adapter.border === "string" && /^#[0-9a-fA-F]{6}$/.test(adapter.border)
    readonly property color borderColour: root.hasBorderColour ? adapter.border : Qt.rgba(1, 1, 1, 0.06)

    // Centre clock size in px. 12 was the original; it rendered noticeably
    // soft at that size, so a theme can bump it.
    readonly property int clockSize: {
        const n = Number(adapter.clockSize);
        return isFinite(n) && n >= 8 && n <= 24 ? Math.round(n) : 12;
    }

    // Size of the "ddd d" date readout at the right of the bar, same idea and
    // same 12px default as the clock.
    readonly property int dateSize: {
        const n = Number(adapter.dateSize);
        return isFinite(n) && n >= 8 && n <= 24 ? Math.round(n) : 12;
    }

    // Where the bar's bottom edge sits from the top of the screen: what the
    // layer surface's height and exclusive zone are, and the line the popup
    // panels and toasts hang below.
    readonly property int barBottom: root.gap + root.barHeight

    FileView {
        path: Quickshell.shellPath("style.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool rounded: false
            property real radius: 10
            property real gap: 8
            property string border: ""
            property real clockSize: 12
            property real dateSize: 12
        }
    }
}
