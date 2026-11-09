# sddm

SDDM greeter themes. These install to `/usr/share/sddm/themes/<name>`
(system-wide, not `~/.config` or `~/.local`), so they're kept out of
`../configs` and installed separately — see
[`../../Scripts/extra/install_sddm_theme.sh`](../../Scripts/extra/install_sddm_theme.sh).

## pixel-sakura

From [Darkkal44/qylock](https://github.com/Darkkal44/qylock) (GPLv3).

Dependencies: `sddm` `qt6-declarative` `qt6-5compat` `qt6-multimedia`
`qt6-multimedia-ffmpeg` (Qt 6 Multimedia plays the background video through
its FFmpeg backend, so no GStreamer plugins are needed)
