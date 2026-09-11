#!/usr/bin/env bash
# Installs Configs/sddm/pixel-sakura as the active SDDM theme (system-wide, needs sudo).

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

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

# ...unless something outranks the dropin we just wrote. SDDM loads
# /usr/lib/sddm/sddm.conf.d/*.conf, then /etc/sddm.conf.d/*.conf in
# alphabetical order, then /etc/sddm.conf LAST -- and later wins. So a
# Current= line in /etc/sddm.conf, or in any dropin sorting after
# theme.conf, silently overrides this install and the greeter comes up
# with a different theme for no visible reason. Warn instead of editing:
# /etc/sddm.conf isn't a file this script owns.
override_found=0

if [ -f /etc/sddm.conf ] && grep -qE '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf; then
    other="$(grep -E '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf | tail -n1 | cut -d= -f2- | tr -d '[:space:]')"
    if [ "$other" != "$themeName" ]; then
        override_found=1
        print_log "WARNING: /etc/sddm.conf sets Current=${other:-<empty>} and is read AFTER"
        print_log "  ${sddmConf}, so it wins. Fix with:"
        print_log "    sudo sed -i 's|^Current=.*|Current=${themeName}|' /etc/sddm.conf"
    fi
fi

for f in "$sddmConfDir"/*.conf; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "$(basename "$sddmConf")" ] && continue
    [[ "$base" > "$(basename "$sddmConf")" ]] || continue
    if grep -qE '^[[:space:]]*Current[[:space:]]*=' "$f"; then
        override_found=1
        print_log "WARNING: ${f} also sets Current= and sorts after"
        print_log "  $(basename "$sddmConf"), so it wins. Edit or remove it."
    fi
done

if [ "$override_found" -eq 0 ]; then
    print_log "SDDM theme '${themeName}' is now active."
else
    print_log "SDDM theme '${themeName}' installed, but see the warnings above -- it is NOT active yet."
fi
