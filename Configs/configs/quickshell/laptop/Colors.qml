pragma Singleton

// The dock's palette AND its per-theme shape, both read from generated JSON
// files in this directory rather than hardcoded in each delegate.
//
// COLOURS -- colors.json. The same "last write wins" arrangement kitty and
// starship use:
//
//   theme-switcher/apply-theme.sh  writes it from the ACTIVE theme's
//                                  colors.json (for Sakura, matugen has just
//                                  regenerated that from the wallpaper --
//                                  dynamic_colors: true)
//   hypr/apply_wallpaper.sh        writes it from pywal's palette on every
//                                  wallpaper pick
//
// This used to read the accent alone, with every other colour in the dock
// (the bar's dark-teal background, the grey-green icons and text) fixed --
// so on Default (true black + turquoise) the bar was a teal-tinted slab that
// matched nothing else. Now background, text, icons and the low-battery /
// unread red all come from the theme too.
//
// SHAPE -- style.json, written by apply-theme.sh from theme.json's
// "quickshell" block on every theme apply. A theme that says nothing gets
// the flat edge-to-edge strip this dock has always been; Default asks for
// floating, rounded islands with a light outline and a larger clock and date:
//
//   "quickshell": { "config": "laptop", "layout": "islands",
//                   "rounded": true, "radius": 15, "gap": 8,
//                   "border": "#9aa3a8", "clockSize": 14, "dateSize": 14 }
//
// Sakura asks for islands too, squarer and tucked closer to the top edge
// ("radius": 8, "gap": 10, "topGap": 4).
//
// The shape lived in a BarStyle.qml singleton of its own for a while. On a
// live install every BarStyle.* read in the dock came back undefined -- a
// 100px-tall square bar (Quickshell's default window size) with no outline --
// while this file, a singleton of exactly the same form, kept working. So the
// shape lives here now, in the singleton that's proven to resolve.
//
// FileView's watchChanges means the dock repaints the moment either file is
// written -- no restart, no theme re-apply.
//
// `pragma Singleton` is the FIRST line on purpose: there's no qmldir here, so
// Quickshell has to spot it by scanning the file, and nothing about a long
// comment header in front of it should get a say in whether it does.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ================= colours =================

    // What the dock shipped with, and the fallback whenever colors.json is
    // missing, unreadable, or holds something that isn't a hex colour.
    readonly property color fallbackAccent: "#c8102e"

    // The dock background is a dark translucent strip, so an accent pulled
    // from a dark wallpaper can come out nearly invisible against it. Anything
    // below this relative luminance gets mixed toward white until it clears
    // the floor. 0.22 lets the shipped fallback #c8102e (0.2246) through
    // untouched.
    readonly property real minLuminance: 0.22

    // Two steps on purpose. adapter.* are JS *strings*; a colour's .r/.g/.b
    // only exist on an actual QML color value, so handing the raw string to
    // ensureContrast() made luminance() read undefined channels and render
    // black. Assigning through a `property color` first performs the
    // coercion.
    readonly property color rawAccent: root.isHex(adapter.accent) ? adapter.accent : root.fallbackAccent
    readonly property color accent: root.ensureContrast(root.rawAccent)

    // Body text, and the base of every derived tone below.
    readonly property color text: root.isHex(adapter.fg) ? adapter.fg : "#eaf0ee"
    // Labels a step down from the clock (the date, the battery percentage).
    readonly property color textSoft: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.85)
    // Icons at rest. Derived from the foreground rather than read from
    // fg_dim: some themes' fg_dim (Default's #5a676b) is meant for disabled
    // text and all but disappears against a black bar.
    readonly property color icon: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.72)
    // Off / unlit: inactive workspace pips, bluetooth powered down.
    readonly property color muted: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.30)

    // Low battery, unread notifications, critical toasts.
    readonly property color red: root.ensureContrast(root.isHex(adapter.red) ? adapter.red : "#f87171")

    // The bar background: the theme's own background, kept dark (capped
    // luminance -- a wallpaper-generated bg can come out mid-grey) and at the
    // same 55% alpha the dock has always had, which every theme's
    // hyprland.lua.tpl blurs through ignore_alpha = 0.2.
    readonly property color rawBg: root.isHex(adapter.bg) ? adapter.bg : "#0a1412"
    readonly property color barBase: root.capLuminance(root.rawBg, 0.10)
    readonly property color barBg: Qt.rgba(root.barBase.r, root.barBase.g, root.barBase.b, 0.55)
    // Toasts sit over arbitrary windows, not just wallpaper -- a little more
    // body behind their text.
    readonly property color cardBg: Qt.rgba(root.barBase.r, root.barBase.g, root.barBase.b, 0.72)

    function isHex(s) {
        return typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s);
    }

    // sRGB coefficients on the non-linearised channels: the right shape for
    // "will this disappear against a dark bar", with no pow() per frame.
    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Mix toward white until luminance reaches the floor. Linear per channel,
    // so it inverts exactly -- and unlike Qt.lighter() it works on pure black.
    function ensureContrast(c) {
        const L = root.luminance(c);
        if (!isFinite(L) || L >= root.minLuminance)
            return c;
        const t = (root.minLuminance - L) / (1 - L);
        return Qt.rgba(c.r + (1 - c.r) * t, c.g + (1 - c.g) * t, c.b + (1 - c.b) * t, c.a);
    }

    // The mirror: scale down until luminance is at most `max`.
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

        JsonAdapter {
            id: adapter
            property string accent: "#c8102e"
            // Empty, not a colour: an absent key means "use the fallback
            // above", which isHex() decides.
            property string bg: ""
            property string fg: ""
            property string red: ""
        }
    }

    // ================= shape =================

    // The bar itself, excluding any gap around it.
    readonly property int barHeight: 34

    // "islands": three separate islands -- workspaces (+ CPU/RAM when they
    // fit) on the left, the clock in the centre, the controls on the right,
    // the two side islands always the same width. Anything else: one bar.
    readonly property bool barIslands: style.layout === "islands"

    // Floating + rounded, or flat and flush with the screen edges. Islands
    // always float -- three islands flush against the edges would just be a
    // bar with two notches in it.
    readonly property bool barRounded: style.rounded === true || root.barIslands

    // How far a rounded bar floats in from the top, left and right edges.
    // Zero when flat: a square bar runs edge to edge as it always has.
    readonly property int barGap: root.barRounded ? Math.max(0, Math.min(40, Number(style.gap) || 0)) : 0

    // The top edge's share of that, when a theme wants it different from
    // the sides ("topGap"). Unset (-1, apply-theme.sh's default) means the
    // same as gap, so a theme that only sets gap looks as it always did.
    readonly property int barTopGap: {
        if (!root.barRounded) return 0;
        const n = Number(style.topGap);
        return isFinite(n) && n >= 0 ? Math.min(40, Math.round(n)) : root.barGap;
    }

    readonly property int barRadius: root.barRounded ? Math.max(0, Math.min(root.barHeight / 2, Number(style.radius) || 0)) : 0

    // The outline: the theme's colour when it names one, otherwise the faint
    // white hairline the flat bar has always had.
    readonly property color barBorder: root.isHex(style.border) ? style.border : Qt.rgba(1, 1, 1, 0.06)

    // Clock and date sizes in px. 12 was the original; it rendered soft at
    // that size, so a theme can bump either.
    readonly property int clockSize: {
        const n = Number(style.clockSize);
        return isFinite(n) && n >= 8 && n <= 24 ? Math.round(n) : 12;
    }
    readonly property int dateSize: {
        const n = Number(style.dateSize);
        return isFinite(n) && n >= 8 && n <= 24 ? Math.round(n) : 12;
    }

    // Font for the dock's TEXT -- clock, date, battery percentage, CPU/RAM.
    // A theme can name one ("font" in its "quickshell" block); apply-theme.sh
    // resolves "font": "kitty" to whatever kitty.conf's font_family is, so
    // the bar matches the terminal. Icons don't use this: they stay on
    // JetBrainsMono Nerd Font, which is known to carry every glyph the dock
    // draws, whatever font the text is in.
    readonly property string textFont: (typeof style.font === "string" && style.font.length > 0) ? style.font : "JetBrainsMono Nerd Font"

    // Where the bar's bottom edge sits from the top of the screen: the layer
    // surface's height and exclusive zone, and the line the popup panels and
    // toasts hang below.
    readonly property int barBottom: root.barTopGap + root.barHeight

    FileView {
        path: Quickshell.shellPath("style.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: style
            property string layout: "single"
            property string font: ""
            property bool rounded: false
            property real radius: 10
            property real gap: 8
            property real topGap: -1
            property string border: ""
            property real clockSize: 12
            property real dateSize: 12
        }
    }
}
