pragma Singleton
// Palette for every HyKr desktop surface in this shell (launcher, clipboard,
// pickers, control centre, OSD).
//
// colors.json next to this file is the same palette file every bar shell
// reads: apply-theme.sh rewrites every quickshell/*/colors.json on a theme
// switch and apply_wallpaper.sh does the same on a wallpaper pick, so this
// shell follows the theme with no code of its own. FileView watches it, so a
// running shell recolours live.
//
// Unlike the bars, these surfaces float over arbitrary windows rather than the
// wallpaper, so the panel background is mostly opaque.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---------------- palette ----------------
    readonly property color bg: root.capLuminance(root.pick(palette.bg, "#11111b"), 0.12)
    readonly property color surface: root.pick(palette.surface, "#1e1e2e")
    readonly property color surface2: root.pick(palette.surface2, "#313244")
    readonly property color text: root.pick(palette.fg, "#cdd6f4")
    readonly property color textDim: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.62)
    readonly property color textFaint: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.38)
    readonly property color accent: root.ensureContrast(root.pick(palette.accent, "#89b4fa"), 0.22)
    readonly property color accentAlt: root.ensureContrast(root.pick(palette.accent_alt, "#94e2d5"), 0.22)
    readonly property color red: root.ensureContrast(root.pick(palette.red, "#f38ba8"), 0.22)
    readonly property color green: root.ensureContrast(root.pick(palette.green, "#a6e3a1"), 0.22)
    readonly property color yellow: root.ensureContrast(root.pick(palette.yellow, "#f9e2af"), 0.22)

    // Surfaces built from the palette.
    readonly property color panel: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.94)
    readonly property color card: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.06)
    readonly property color hover: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
    readonly property color selected: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
    readonly property color border: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.10)
    readonly property color backdrop: Qt.rgba(0, 0, 0, 0.35)
    // Text on an accent-filled surface (an active toggle, the play button).
    readonly property color onAccent: root.luminance(root.accent) > 0.55 ? "#111111" : "#ffffff"

    // ---------------- shape and type ----------------
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int radius: 16
    readonly property int radiusSmall: 10
    readonly property int fontSize: 13
    readonly property int fontSmall: 11

    // ---------------- helpers ----------------
    function isHex(s) {
        return typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s);
    }

    // A JS string from colors.json, or the fallback. Returned as a string; the
    // color-typed properties above do the conversion.
    function pick(value, fallback) {
        return root.isHex(value) ? value : fallback;
    }

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Mix toward white until luminance reaches `min` (works on pure black,
    // unlike Qt.lighter). Same approach as the Laptop dock's Colors.qml.
    function ensureContrast(value, min) {
        const c = Qt.color(value);
        const L = root.luminance(c);
        if (!isFinite(L) || L >= min)
            return c;
        const t = (min - L) / (1 - L);
        return Qt.rgba(c.r + (1 - c.r) * t, c.g + (1 - c.g) * t, c.b + (1 - c.b) * t, 1);
    }

    function capLuminance(value, max) {
        const c = Qt.color(value);
        const L = root.luminance(c);
        if (!isFinite(L) || L <= max)
            return c;
        const t = max / L;
        return Qt.rgba(c.r * t, c.g * t, c.b * t, 1);
    }

    FileView {
        path: Quickshell.shellPath("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: palette
            // Empty means "use the fallback" (pick() decides).
            property string bg: ""
            property string surface: ""
            property string surface2: ""
            property string fg: ""
            property string fg_dim: ""
            property string accent: ""
            property string accent_alt: ""
            property string green: ""
            property string red: ""
            property string orange: ""
            property string yellow: ""
            property string blue: ""
        }
    }
}
