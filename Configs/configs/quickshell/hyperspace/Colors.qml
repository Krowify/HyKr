// The whole Hyperspace palette, read from a generated colors.json rather
// than hardcoded per delegate.
//
// This is the same "last write wins" arrangement kitty, starship and the
// Laptop dock already use, just carrying a full palette instead of a single
// accent:
//
//   theme-switcher/apply-theme.sh  writes it from the ACTIVE theme's
//                                  colors.json (which, for Hyperspace, matugen
//                                  has just regenerated from the wallpaper --
//                                  dynamic_colors: true)
//   hypr/apply_wallpaper.sh        writes it from pywal's own palette on every
//                                  wallpaper pick, the same slots the Hyprland
//                                  border, rofi and wofi accents already use
//
// whichever ran most recently wins. FileView's watchChanges means the dock
// repaints the moment either script writes -- no restart, no theme re-apply.
//
// Why a full palette and not just the accent the Laptop dock reads: every
// surface in this shell (island backgrounds, body text, dim labels, the
// "connected"/"low battery" states) is supposed to track the wallpaper here,
// not just the active-workspace pill. Anything still hardcoded would drift
// visibly against a wallpaper-derived accent.
//
// A sibling `pragma Singleton` with no qmldir, resolved unqualified from
// DockBar.qml and the panels -- exactly how DockState.qml works too.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The shipped Hyperspace palette, and the fallback whenever colors.json
    // is missing, unreadable, or holds something that isn't a hex colour.
    readonly property color fallbackAccent: "#7fd6cf"
    readonly property color fallbackBg: "#0b1016"
    readonly property color fallbackFg: "#e6eef5"

    // Island translucency. 0.55 deliberately matches the Laptop dock's own
    // alpha, and the theme's hyprland.lua.tpl blurs this namespace with
    // ignore_alpha = 0.2 -- so an island clears the threshold and gets
    // blurred, while the fully transparent gaps BETWEEN the islands stay
    // below it and are left alone. Alpha always lives in a colour here,
    // never in an Item's `opacity` property: opacity cascades to children
    // in Qt Quick, which would fade every icon and label along with the
    // background (the exact bug the Laptop DockBar's header documents).
    readonly property real islandAlpha: 0.55

    // The dock's islands are dark translucent pills, so an accent pulled from
    // a dark wallpaper can come out nearly invisible against one. Anything
    // below this relative luminance is mixed toward white until it clears the
    // floor. 0.22 is the same floor the Laptop dock uses.
    readonly property real minLuminance: 0.22

    // Two steps on purpose, per the Laptop dock's Colors.qml: adapter.* are JS
    // *strings*, and a colour's .r/.g/.b only exist on an actual QML color
    // value. Assigning through a `property color` first performs the
    // coercion, so the arithmetic in ensureContrast() below gets real
    // channels instead of NaN (which renders black).
    readonly property color rawAccent: root.isHex(adapter.accent) ? adapter.accent : root.fallbackAccent
    readonly property color rawAccentAlt: root.isHex(adapter.accent_alt) ? adapter.accent_alt : root.rawAccent
    readonly property color rawGreen: root.isHex(adapter.green) ? adapter.green : "#8fd6a6"
    readonly property color rawRed: root.isHex(adapter.red) ? adapter.red : "#e0707d"

    readonly property color accent: root.ensureContrast(root.rawAccent)
    readonly property color accentAlt: root.ensureContrast(root.rawAccentAlt)
    readonly property color good: root.ensureContrast(root.rawGreen)
    readonly property color bad: root.ensureContrast(root.rawRed)

    readonly property color bg: root.isHex(adapter.bg) ? adapter.bg : root.fallbackBg
    readonly property color surface: root.isHex(adapter.surface) ? adapter.surface : root.bg
    readonly property color surface2: root.isHex(adapter.surface2) ? adapter.surface2 : root.surface
    readonly property color text: root.isHex(adapter.fg) ? adapter.fg : root.fallbackFg
    readonly property color textDim: root.isHex(adapter.fg_dim) ? adapter.fg_dim : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.65)

    // A wallpaper-derived background can land anywhere from near-black to a
    // mid grey-blue. Floor it downward (the mirror of ensureContrast) so the
    // islands and panels stay dark enough for the accent and the white-ish
    // body text to read against them at 55% alpha over an arbitrary
    // wallpaper.
    readonly property color panelBase: root.capLuminance(root.bg, 0.10)

    // What the islands and panels actually paint. Two alphas: the bar's
    // islands sit directly over the wallpaper, the popup panels want a bit
    // more body behind a list of text.
    readonly property color island: Qt.rgba(root.panelBase.r, root.panelBase.g, root.panelBase.b, root.islandAlpha)
    readonly property color panel: Qt.rgba(root.panelBase.r, root.panelBase.g, root.panelBase.b, 0.72)

    // Hairlines and fills derived from the accent, so even the borders track
    // the wallpaper instead of being a fixed white alpha.
    readonly property color hairline: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
    readonly property color accentSoft: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
    // Unlit workspace pips, inactive toggles, panel row separators. Neutral
    // on purpose: tinting these too would leave nothing for the accent to
    // contrast against.
    readonly property color muted: Qt.rgba(1, 1, 1, 0.22)
    readonly property color mutedFill: Qt.rgba(1, 1, 1, 0.08)

    // Icons at rest. Between textDim and muted -- visible, but clearly not
    // the active one.
    readonly property color icon: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.72)

    function isHex(s) {
        return typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s);
    }

    // sRGB coefficients applied to the non-linearised channels. Not a
    // colorimetrically exact luminance, but the right shape for "is this
    // going to disappear against a dark island" and free of a pow() per frame.
    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Mixing toward white is linear per channel, so luminance after mixing by
    // t is L + (1 - L) * t. That inverts exactly -- no search loop, and unlike
    // Qt.lighter() it still works on a colour with zero value (pure black),
    // which Qt.lighter leaves untouched.
    function ensureContrast(c) {
        const L = root.luminance(c);
        // Anything that isn't a real colour would otherwise propagate NaN
        // through the mix below and render black. Hand it back untouched and
        // let the caller's own coercion decide.
        if (!isFinite(L))
            return c;
        if (L >= root.minLuminance)
            return c;
        const t = (root.minLuminance - L) / (1 - L);
        return Qt.rgba(c.r + (1 - c.r) * t, c.g + (1 - c.g) * t, c.b + (1 - c.b) * t, c.a);
    }

    // The exact mirror: scale every channel down until luminance is at most
    // `max`. Scaling is linear in luminance too, so the factor is just the
    // ratio -- again no search loop.
    function capLuminance(c, max) {
        const L = root.luminance(c);
        if (!isFinite(L) || L <= max)
            return c;
        const t = max / L;
        return Qt.rgba(c.r * t, c.g * t, c.b * t, c.a);
    }

    FileView {
        path: Quickshell.shellPath("colors.json")
        watchChanges: true
        onFileChanged: reload()

        // Every field carries the shipped default, so a colors.json written
        // by an older apply-theme.sh (accent only) still yields a complete,
        // coherent palette rather than a half-black dock.
        JsonAdapter {
            id: adapter
            property string bg: "#0b1016"
            property string surface: "#111823"
            property string surface2: "#1b2531"
            property string fg: "#e6eef5"
            property string fg_dim: "#a9bccb"
            property string accent: "#7fd6cf"
            property string accent_alt: "#8fb4d9"
            property string green: "#8fd6a6"
            property string red: "#e0707d"
        }
    }
}
