# Scripts

Conventions (following [HyDE](https://github.com/HyDE-Project/HyDE/tree/master/Scripts)'s script layout):

- Every script computes its own dir and sources the shared lib first:
  ```bash
  scrDir="$(dirname "$(realpath "$0")")"
  source "${scrDir}/global_fn.sh" || {
      echo "Error: unable to source ${scrDir}/global_fn.sh"
      ls -la "${scrDir}/global_fn.sh" 2>&1
      exit 1
  }
  ```
- [`global_fn.sh`](global_fn.sh) is the shared lib — common vars (`repoDir`, `dotsDir`, `confDir`) and helper functions (`print_log`, `link_dot`, …) live there, not duplicated per script.
- Naming: `snake_case`, verb first (`link_dots.sh`), `.sh` for scripts. A script's data file (if any) shares its base name with a different extension (e.g. `dots/waybar.toml`).
- Folders are topics, not install-order stages — no numeric prefixes. [`dots/`](dots) holds per-app manifests, [`extra/`](extra) holds optional/secondary scripts.
- [`pkg_core.lst`](pkg_core.lst) — packages needed to actually run what's in `Configs/` (one per line, `#` comment explaining why). [`pkg_extra.lst`](pkg_extra.lst) — optional apps (not required by anything in `Configs/`). Following HyDE's `pkg_*.lst` naming. Both are read by [`install.sh`](install.sh) via `yay -S --needed`, matching elifouts/Dotfiles' `InstallScripts/` convention.
- [`install.sh`](install.sh) — the single entrypoint. If run as root, hands off to a regular user first (creates one if needed) — `link_dots.sh` and yay's AUR builds can't run as root. From there: `install_gpu_drivers.sh`, `yay` if missing, `pkg_core.lst` (and `pkg_extra.lst` if you opt in), `link_dots.sh`, `enable_services.sh` (sddm/NetworkManager/bluetooth — not optional), then asks before running `extra/install_sddm_theme.sh` and `extra/setup_firewall.sh`.
- [`install_gpu_drivers.sh`](install_gpu_drivers.sh) — detects the GPU via `lspci`, installs `mesa` always and `nvidia-open` if Nvidia is detected. No prompt.
- [`snapshot_monitors.sh`](snapshot_monitors.sh) — freezes the monitor layout this machine is running right now into `~/.config/hypr/monitors.lua`, which [`hyprland.lua`](../Configs/configs/hypr/hyprland.lua) `pcall`-requires. Monitor layout is the one thing in this repo that cannot be shared — `HDMI-A-1` and `eDP-1` are the first HDMI output and the internal panel on nearly any machine — so it is gitignored rather than tracked, and this is how you produce one without hand-editing an example. Reads `hyprctl monitors -j`, pins mode/position/scale/transform (the last two do not survive a reload on their own), skips disabled outputs, and backs up an existing file before replacing it. `--print` to preview, `--preferred` to leave the mode as `preferred` rather than pinning the exact current one. Needs a running Hyprland.
- [`enable_services.sh`](enable_services.sh) — enables `sddm`/`NetworkManager`/`bluetooth`. Not optional: without these a fresh install boots to a TTY with no network or bluetooth, regardless of what packages got installed.
