`blackturq.jpg` is the Blackturq theme's wallpaper, referenced by
`../theme.json`'s `default_wallpaper`.

Upstream HV-dotfiles ships no wallpaper of its own -- its setup.sh just
creates `~/Pictures/backgrounds/` and tells you to put one there. So this
is HyKr's pick, chosen to match the palette rather than inherited:
`Source/wallpapers/radium/a_black_background_with_green_and_blue_squares.jpg`,
a near-black field with teal-green geometry.

It's a relative symlink into `Source/wallpapers/radium/`, not a copy --
same reasoning as the Minimal theme's: the image already ships in this
repo, and `Source/wallpapers` is what `link_dots.sh` symlinks to
`~/wallpapers`, so this is the same file the wallpaper picker offers.

The six `..` hops resolve against the symlink's real location, so this
lands on the right file when apply-theme.sh reads it as
`~/.config/theme-switcher/themes/blackturq/wallpapers/blackturq.jpg`.
de_symlink()'s `cp -rL` dereferences it into a real file if the
theme-switcher tree is ever detached from the repo, so the copy stays
self-contained either way.

To point the theme at something else, re-target the symlink or drop a real
file here under the same name.
