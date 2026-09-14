`hyperspace.png` is the Hyperspace theme's default wallpaper, referenced by
`../theme.json`'s `default_wallpaper`, and the image matugen derives the
whole palette from the first time the theme is applied.

Like the Minimal theme's, it's a relative symlink into
`Source/wallpapers/anime/` rather than a copy: that image
(`a_person_in_the_air_above_a_city.png`) already ships in this repo, and
`Source/wallpapers` is what `link_dots.sh` symlinks to `~/wallpapers`, so
this is the same file the wallpaper picker offers. A copy would put a
second 2.7 MB of identical bytes in git.

The six `..` hops resolve against the symlink's real location, so it still
lands on the right file once `apply-theme.sh` reads it as
`~/.config/theme-switcher/themes/hyperspace/wallpapers/hyperspace.png`.
`de_symlink()` copies this tree with `cp -rL` (follow symlinks) exactly so
this doesn't become a dangling link pointing above `$HOME` the first time a
theme is applied.

Drop more images in this directory to have them offered by the wallpaper
picker `apply-theme.sh` shows when you switch to Hyperspace without naming
a wallpaper -- every one of them re-derives the theme's colours through
matugen, so they don't have to share a palette.
