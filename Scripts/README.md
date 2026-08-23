# Scripts

Conventions (following [HyDE](https://github.com/HyDE-Project/HyDE/tree/master/Scripts)'s script layout):

- Every script computes its own dir and sources the shared lib first:
  ```bash
  scrDir="$(dirname "$(realpath "$0")")"
  source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }
  ```
- [`global_fn.sh`](global_fn.sh) is the shared lib — common vars (`repoDir`, `dotsDir`, `confDir`) and helper functions (`print_log`, `link_dot`, …) live there, not duplicated per script.
- Naming: `snake_case`, verb first (`link_dots.sh`), `.sh` for scripts. A script's data file (if any) shares its base name with a different extension (e.g. `dots/waybar.toml`).
- Folders are topics, not install-order stages — no numeric prefixes. [`dots/`](dots) holds per-app manifests, [`extra/`](extra) holds optional/secondary scripts.
- [`pkg_core.lst`](pkg_core.lst) — packages needed to actually run what's in `Configs/` (one per line, `#` comment explaining why). [`pkg_extra.lst`](pkg_extra.lst) — optional apps (not required by anything in `Configs/`). Following HyDE's `pkg_*.lst` naming. Both are read by [`install.sh`](install.sh) via `yay -S --needed`, matching elifouts/Dotfiles' `InstallScripts/` convention.
- [`install.sh`](install.sh) — the single entrypoint. If run as root, hands off to a regular user first (creates one if needed) — `link_dots.sh` and yay's AUR builds can't run as root. From there: `install_gpu_drivers.sh`, `yay` if missing, `pkg_core.lst` (and `pkg_extra.lst` if you opt in), `link_dots.sh`, `enable_services.sh` (sddm/NetworkManager/bluetooth — not optional), then asks before running `extra/install_sddm_theme.sh` and `extra/setup_firewall.sh`.
- [`install_gpu_drivers.sh`](install_gpu_drivers.sh) — detects the GPU via `lspci`, installs `mesa` always and `nvidia-open` if Nvidia is detected. No prompt.
- [`enable_services.sh`](enable_services.sh) — enables `sddm`/`NetworkManager`/`bluetooth`. Not optional: without these a fresh install boots to a TTY with no network or bluetooth, regardless of what packages got installed.
