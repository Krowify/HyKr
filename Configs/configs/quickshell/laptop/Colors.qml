// Wallpaper-derived accent for the dock, read from a generated colors.json
// rather than hardcoded in each delegate.
//
// This is the same "last write wins" arrangement kitty and starship already
// use, just pointed at a JSON file instead of a conf/toml:
//
//   theme-switcher/apply-theme.sh  writes it from the ACTIVE theme's
//                                  colors.json (which, for the Laptop theme,
//                                  matugen has just regenerated from the
//                                  wallpaper -- dynamic_colors: true)
//   hypr/apply_wallpaper.sh        writes it from pywal's $color4 on every
//                                  wallpaper pick, the same slot the Hyprland
//                                  border, rofi and wofi accents already use
//
// whichever ran most recently wins. FileView's watchChanges means the dock
// repaints the moment either script writes -- no restart, no theme re-apply,
// which is the equivalent of kitty's live `set-colors` over its socket.
//
// A sibling `pragma Singleton` with no qmldir, resolved unqualified from
// DockBar.qml -- exactly how DockState.qml already works in this directory.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // What the dock shipped with before any of this was generated, and the
    // fallback whenever colors.json is missing, unreadable, or holds
    // something that isn't a hex colour.
    readonly property color fallbackAccent: "#c8102e"

    // The dock background is a dark translucent strip, so an accent pulled
    // from a dark wallpaper can come out nearly invisible against it -- the
    // one failure mode a fixed crimson never had. Anything below this
    // relative luminance gets mixed toward white until it clears the floor.
    //
    // 0.22 is chosen so the shipped fallback #c8102e (luminance 0.2246)
    // passes through untouched: the dock looks exactly as it does today
    // until a wallpaper actually drives the accent somewhere darker. A
    // deep matugen red (#5c1a1f, 0.158) lifts to #682b2f; pure black to
    // #383838; anything already mid-tone or brighter is left alone.
    readonly property real minLuminance: 0.22

    readonly property color accent: root.ensureContrast(
        root.isHex(adapter.accent) ? adapter.accent : root.fallbackAccent)

    function isHex(s) {
        return typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s);
    }

    // sRGB coefficients, applied to the non-linearised channels. Not a
    // colorimetrically exact luminance, but the right shape for "is this
    // going to disappear against a dark bar" and free of a pow() per frame.
    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Mixing toward white is linear per channel, so luminance after mixing by
    // t is L + (1 - L) * t. That inverts exactly -- no search loop, and unlike
    // Qt.lighter() it still works on a colour with zero value (pure black),
    // which Qt.lighter leaves untouched.
    function ensureContrast(c) {
        const L = root.luminance(c);
        if (L >= root.minLuminance)
            return c;
        const t = (root.minLuminance - L) / (1 - L);
        return Qt.rgba(c.r + (1 - c.r) * t,
                       c.g + (1 - c.g) * t,
                       c.b + (1 - c.b) * t,
                       c.a);
    }

    FileView {
        path: Quickshell.shellPath("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string accent: "#c8102e"
        }
    }
}
