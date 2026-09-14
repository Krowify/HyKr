# Hyperspace's lock screen shows the theme's own wallpaper rather than a
# flat background colour: apply-theme.sh fills the wallpaper_path token in
# `path` below with the absolute path of whatever wallpaper this theme was
# last applied with -- the one matugen derived every colour here from -- so
# the lock screen and the desktop always agree. If that path comes out
# empty (no wallpaper resolved), hyprlock falls back to `color` on its own.
#
# (Written without the token's own braces so this comment isn't rewritten
# along with the line it describes.)
background {
    monitor =
    path = {{wallpaper_path}}
    color = {{bg}}
    blur_passes = 3
    blur_size = 6
    contrast = 0.9
    brightness = 0.55
    vibrancy = 0.22
    vibrancy_darkness = 0.1
}

general {
    no_fade_in = false
    grace = 0
    disable_loading = true
}

input-field {
    monitor =
    size = 280, 56
    outline_thickness = 2
    dots_size = 0.24
    dots_spacing = 0.3
    dots_center = true
    rounding = 18

    outer_color = {{border}}
    inner_color = {{input_bg}}
    font_color = {{fg}}

    fade_on_empty = true
    placeholder_text = <span foreground="{{fg_hex}}">Enter hyperspace...</span>
    hide_input = false
    position = 0, -130
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    color = {{fg}}
    font_size = 118
    font_family = {{font_family_bold}}
    position = 0, 90
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] date +"%A, %d %B"
    color = {{accent}}
    font_size = 20
    font_family = {{font_family}}
    position = 0, -10
    halign = center
    valign = center
}

label {
    monitor =
    text = hi, $USER
    color = {{fg}}
    font_size = 15
    font_family = {{font_family}}
    position = 0, -60
    halign = center
    valign = center
}
