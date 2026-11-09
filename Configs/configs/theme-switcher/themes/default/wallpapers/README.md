`guitar_case.jpg` is the Default theme's wallpaper, referenced by
`../theme.json`'s `default_wallpaper`:
`Source/wallpapers/anime/a_girl_standing_in_front_of_a_guitar_case.jpg`.

`blackturq.jpg` is the previous default, kept here so it stays pickable:
`Source/wallpapers/radium/a_black_background_with_green_and_blue_squares.jpg`,
a near-black field with teal-green geometry chosen to match the palette.
Upstream HV-dotfiles ships no wallpaper of its own -- its setup.sh just
creates `~/Pictures/backgrounds/` and tells you to put one there.

Both are relative symlinks into `Source/wallpapers/`, not copies -- same
reasoning as the Minimal theme's: the images already ship in this repo, and
`Source/wallpapers` is what `link_dots.sh` symlinks to `~/wallpapers`, so
these are the same files the wallpaper picker offers.

The six `..` hops resolve against the symlink's real location, so each
lands on the right file when apply-theme.sh reads it as
`~/.config/theme-switcher/themes/default/wallpapers/<name>.jpg`.
de_symlink()'s `cp -rL` (and `Scripts/sync_configs.sh --apply`) dereference
them into real files if the theme-switcher tree is ever detached from the
repo, so the copy stays self-contained either way.

To point the theme at something else, add another symlink (or a real file)
here and change `default_wallpaper` in `../theme.json`.
