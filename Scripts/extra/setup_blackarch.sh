#!/usr/bin/env bash
# Add the BlackArch repository to an existing HyKr install -- carefully, and
# without installing any tools by default.
#
# BlackArch is NOT a distro to switch to: it is an unofficial pacman
# repository (plus a live ISO). "Running BlackArch" on this machine means
# keeping this Arch install exactly as it is and adding one more repo, so
# every HyKr config, theme and script keeps working untouched.
#
# The two things that can actually break this machine are both about
# precedence, not about the tools:
#
#   1. Repo ORDER. BlackArch rebuilds some ordinary packages. pacman
#      resolves same-name packages by the order sections appear in
#      pacman.conf, so [blackarch] must come LAST, after core/extra/
#      multilib. strap.sh appends it, which is normally correct -- this
#      script verifies it rather than trusting it, and refuses to go on if
#      it is wrong.
#   2. SHADOWING. Even placed last, BlackArch can carry a HIGHER version of
#      a package HyKr depends on, and a later -Syu would then pull it in.
#      python-pywal16 is the one that matters most here: every theme-switcher
#      template renders from the palette it generates, and it
#      provides/replaces python-pywal, so a swap would look like a normal
#      upgrade and quietly cost the --cols16 flag. This script reports every
#      such overlap before anything is installed, reading the watch list
#      straight out of pkg_core.lst/pkg_extra.lst so it stays current as
#      those change.
#
# Modes:
#   setup_blackarch.sh                 back up, update, strap, verify, report
#   setup_blackarch.sh --report-only   just the shadowing report (already strapped)
#   setup_blackarch.sh --install "blackarch-recon blackarch-webapp"
#                                      ...and then install those groups
#   setup_blackarch.sh --yes           don't prompt (still never installs tools
#                                      unless --install was given)
#
# Deliberately does NOT install the `blackarch` group. That is tens of GB and
# pulls conflicting dependencies; category groups are the supported way in.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

ASSUME_YES=false
REPORT_ONLY=false
INSTALL_GROUPS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y)      ASSUME_YES=true; shift ;;
        --report-only) REPORT_ONLY=true; shift ;;
        --install)     INSTALL_GROUPS="${2:-}"; shift 2 ;;
        -h|--help)     sed -n '2,40p' "$(realpath "$0")"; exit 0 ;;
        *)             print_log "Unknown argument: $1"; exit 1 ;;
    esac
done

# Same shape as setup_suspend.sh's: every prompt guards a change that has a
# safe skip, so "no" is always a valid answer.
confirm() {
    local reply
    $ASSUME_YES && return 0
    [[ -t 0 ]] || return 1
    read -rp "[HyKr] $1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

if ! command -v pacman &>/dev/null; then
    print_log "This targets Arch Linux (pacman not found). Aborting."
    exit 1
fi

PACMAN_CONF="/etc/pacman.conf"
BACKUP_DIR="${HOME}/.local/share/hykr/blackarch"
STRAP_TMP=""
cleanup() { [[ -n "$STRAP_TMP" && -d "$STRAP_TMP" ]] && rm -rf "$STRAP_TMP"; }
trap cleanup EXIT

# --------------------------------------------------- // Repo order check
# Returns 0 only when [blackarch] is the last repo section in pacman.conf.
# Reads section headers in file order; the last one must be blackarch.
blackarch_is_last() {
    local last
    last="$(grep -oP '^\[\K[^]]+' "$PACMAN_CONF" | grep -v '^options$' | tail -n1)"
    [[ "$last" == "blackarch" ]]
}

repo_order_report() {
    print_log "Repo order in ${PACMAN_CONF} (last one wins name collisions):"
    grep -n '^\[' "$PACMAN_CONF" | sed 's/^/    /'
}

# --------------------------------------------------- // Shadowing report
# Packages HyKr asks for (pkg_core.lst + pkg_extra.lst, first field, comments
# stripped) that BlackArch ALSO ships. Anything listed is a package whose
# next upgrade could come from BlackArch instead of the official repos.
hykr_wanted_packages() {
    cat "${scrDir}/pkg_core.lst" "${scrDir}/pkg_extra.lst" 2>/dev/null \
        | sed 's/#.*//' \
        | awk 'NF {print $1}' \
        | sort -u
}

shadow_report() {
    if ! pacman -Slq blackarch &>/dev/null; then
        print_log "BlackArch repo not readable yet -- run 'sudo pacman -Sy' first."
        return 1
    fi

    local ba_list hykr_list installed
    ba_list="$(mktemp)"; hykr_list="$(mktemp)"; installed="$(mktemp)"
    pacman -Slq blackarch | sort -u > "$ba_list"
    hykr_wanted_packages > "$hykr_list"
    pacman -Qq | sort -u > "$installed"

    print_log "BlackArch ships $(wc -l < "$ba_list") packages."

    print_log "HyKr packages that BlackArch also ships (watch these on every -Syu):"
    if ! comm -12 "$hykr_list" "$ba_list" | sed 's/^/    /' | grep -q .; then
        print_log "    none -- no overlap with HyKr's own package lists"
    else
        comm -12 "$hykr_list" "$ba_list" | sed 's/^/    /'
    fi

    print_log "Installed packages BlackArch also ships (broader -- includes deps):"
    comm -12 "$installed" "$ba_list" | wc -l | sed 's/^/    /;s/$/ package(s)/'
    print_log "    full list: comm -12 <(pacman -Qq | sort) <(pacman -Slq blackarch | sort)"

    # The single most load-bearing package for HyKr's theming, called out by
    # name because a silent swap here degrades every template at once.
    if pacman -Qq python-pywal16 &>/dev/null; then
        print_log "python-pywal16 (theming pipeline) resolves to:"
        pacman -Si python-pywal16 2>/dev/null | grep -E '^(Repository|Version)' | sed 's/^/    /'
        if pacman -Slq blackarch 2>/dev/null | grep -qx 'python-pywal'; then
            print_log "    NOTE: BlackArch ships python-pywal. It provides/replaces"
            print_log "    python-pywal16, so a -Syu may offer to swap them. Decline:"
            print_log "    plain pywal has no --cols16, which wallpaper.sh/link_dots.sh need."
        fi
    fi

    rm -f "$ba_list" "$hykr_list" "$installed"
}

# --------------------------------------------------- // Report-only mode
if $REPORT_ONLY; then
    repo_order_report
    if blackarch_is_last; then
        print_log "[blackarch] is last in ${PACMAN_CONF} -- correct."
    else
        print_log "WARNING: [blackarch] is NOT the last repo section."
        print_log "Move it to the bottom of ${PACMAN_CONF}, or BlackArch's rebuilds"
        print_log "of ordinary packages will win over the official ones."
    fi
    shadow_report || true
    exit 0
fi

# --------------------------------------------------- // Backups
print_log "Backing up pacman.conf and the current package list to ${BACKUP_DIR}"
mkdir -p "$BACKUP_DIR"
cp "$PACMAN_CONF" "${BACKUP_DIR}/pacman.conf.$(date +%Y%m%d-%H%M%S).bak"
pacman -Qqe > "${BACKUP_DIR}/pkglist-explicit-$(date +%Y%m%d-%H%M%S).txt"
print_log "Backed up. Restore the package list later with: pacman -S --needed - < <file>"

# --------------------------------------------------- // Full update first
# Adding a third-party repo to a partially-updated system is how a partial
# upgrade happens by accident on the very next install.
if confirm "Run a full system update now (sudo pacman -Syu) before strapping?"; then
    sudo pacman -Syu
    print_log "If the kernel was updated, reboot before continuing."
    confirm "Continue without rebooting?" || { print_log "Stopping here. Re-run after reboot."; exit 0; }
else
    print_log "Skipping the update. Strapping onto a stale system risks a partial upgrade."
    confirm "Really continue without updating?" || exit 0
fi

# --------------------------------------------------- // strap.sh
if blackarch_is_last || grep -q '^\[blackarch\]' "$PACMAN_CONF"; then
    print_log "[blackarch] already present in ${PACMAN_CONF} -- skipping strap.sh"
else
    STRAP_TMP="$(mktemp -d)"
    print_log "Fetching strap.sh"
    curl -fsSL -o "${STRAP_TMP}/strap.sh" https://blackarch.org/strap.sh

    # Not hardcoded on purpose: BlackArch rotates strap.sh, so a checksum
    # baked in here would go stale and train you to ignore it. Compare it
    # against the value published on the downloads page, by eye, once.
    print_log "strap.sh SHA1: $(sha1sum "${STRAP_TMP}/strap.sh" | awk '{print $1}')"
    print_log "Compare that against the SHA1 on https://blackarch.org/downloads.html"
    confirm "Does the SHA1 match the published value?" || {
        print_log "Not proceeding. You are about to run this as root -- a mismatch matters."
        exit 1
    }

    chmod +x "${STRAP_TMP}/strap.sh"
    print_log "Running strap.sh (adds the keyring and the [blackarch] repo)"
    sudo "${STRAP_TMP}/strap.sh"
fi

# --------------------------------------------------- // Verify placement
repo_order_report
if blackarch_is_last; then
    print_log "[blackarch] is last -- official repos keep precedence for shared names."
else
    print_log "WARNING: [blackarch] is NOT the last repo section in ${PACMAN_CONF}."
    print_log "Fix that before installing anything: move the [blackarch] block to the"
    print_log "bottom of the file. Left as-is, BlackArch's rebuilds of ordinary"
    print_log "packages outrank the official ones and can break this desktop."
    exit 1
fi

print_log "Syncing databases"
sudo pacman -Sy

# --------------------------------------------------- // Report
shadow_report || true

print_log "Previewing pending upgrades (review before applying):"
pacman -Qu | sed 's/^/    /' || print_log "    none"

# --------------------------------------------------- // Optional install
if [[ -n "$INSTALL_GROUPS" ]]; then
    print_log "Installing groups: ${INSTALL_GROUPS}"
    # shellcheck disable=SC2086
    sudo pacman -S --needed $INSTALL_GROUPS
else
    print_log "No tools installed -- that is the default."
    print_log "List categories:  pacman -Sg | grep blackarch"
    print_log "Install some:     sudo pacman -S blackarch-recon blackarch-webapp"
    print_log "Never install the bare 'blackarch' group (tens of GB, conflicting deps)."
fi

print_log ""
print_log "Ongoing rules for this machine:"
print_log "  * Always 'pacman -Syu'. Never 'pacman -Sy <pkg>' -- partial upgrades break Hyprland."
print_log "  * Re-run this script with --report-only after any big upgrade."
print_log "  * Keep the keyring fresh: sudo pacman -S blackarch-keyring"
print_log "  * setup_firewall.sh denies inbound, so listeners need a temporary opening:"
print_log "      sudo firewall-cmd --add-port=4444/tcp   (no --permanent; clears on reload)"
