#!/usr/bin/env bash
# Installs Configs/sddm/pixel-sakura as the active SDDM theme (system-wide, needs sudo).

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

themeName="pixel-sakura"
themeSrc="${repoDir}/Configs/sddm/${themeName}"
systemThemesDir="/usr/share/sddm/themes"
sddmConfDir="/etc/sddm.conf.d"
sddmConf="${sddmConfDir}/theme.conf"

print_log "Installing SDDM theme: ${themeName}"

sudo mkdir -p "$systemThemesDir"
sudo rm -rf "${systemThemesDir}/${themeName}"
sudo cp -r "$themeSrc" "${systemThemesDir}/${themeName}"

sudo mkdir -p "$sddmConfDir"
if [ ! -f "$sddmConf" ]; then
    printf '[Theme]\nCurrent=%s\n' "$themeName" | sudo tee "$sddmConf" > /dev/null
elif grep -q '^Current=' "$sddmConf"; then
    sudo sed -i "s|^Current=.*|Current=${themeName}|" "$sddmConf"
elif grep -q '^\[Theme\]' "$sddmConf"; then
    sudo sed -i "/^\[Theme\]/a Current=${themeName}" "$sddmConf"
else
    printf '\n[Theme]\nCurrent=%s\n' "$themeName" | sudo tee -a "$sddmConf" > /dev/null
fi

print_log "SDDM theme '${themeName}' is now active."
