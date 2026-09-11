`minimal.png` is the Minimal theme's wallpaper, referenced by
`../theme.json`'s `default_wallpaper`.

It's a relative symlink into `Source/wallpapers/anime/`, not a copy: that
image already ships in this repo (and `Source/wallpapers` is what
`link_dots.sh` symlinks to `~/wallpapers`, so it's the same file the
wallpaper picker offers), and duplicating it here would put a second
1.7 MB copy of identical bytes in git.

The six `..` hops resolve against the symlink's real location, so this
still lands on the right file when apply-theme.sh reads it as
`~/.config/theme-switcher/themes/minimal/wallpapers/minimal.png` --
`~/.config/theme-switcher` is itself a symlink into the repo, and
de_symlink() never converts it to a real copy the way it does hypr/ and
quickshell/. To point the theme at something else, just re-target the
symlink (or drop a real file here under the same name).
