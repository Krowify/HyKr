background {
    monitor =
    # Flat background, not the wallpaper: Blackturq's whole premise is a
    # true-black field, and {{bg}} is #0a0a0a at full alpha. Uncomment the
    # path below (and drop the colour) to show the wallpaper instead --
    # apply-theme.sh renders {{wallpaper_path}} as an absolute path, or as
    # "" when nothing resolved, which hyprlock treats as "use color".
    # path = {{wallpaper_path}}
    color = {{bg}}
    blur_passes = 2
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
}

general {
    no_fade_in = false
    grace = 0
    disable_loading = true
}

input-field {
    monitor =
    size = 250, 55
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.3
    dots_center = true

    outer_color = {{border}}
    inner_color = {{input_bg}}
    font_color = {{fg}}

    fade_on_empty = true
    placeholder_text = <span foreground="{{fg_hex}}">Password</span>
    hide_input = false
    position = 0, -130
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    color = {{fg}}
    font_size = 110
    font_family = {{font_family_bold}}
    position = 0, 70
    halign = center
    valign = center
}

label {
    monitor =
    text = $USER
    color = {{accent}}
    font_size = 22
    font_family = {{font_family}}
    position = 0, -50
    halign = center
    valign = center
}
