#!/usr/bin/env bash
# Network state for the desktop shell's network panel, tab-separated:
#
#   radio  on|off|none
#   wired  <connection name>                      (only when ethernet is up)
#   net    <ssid>  <signal 0-100>  <security or empty>  <in use yes|no>  <saved yes|no>
#
# One `net` line per network name: several access points broadcasting the
# same SSID are merged, keeping the strongest signal. Hidden networks (no
# name) are left out. Uses NetworkManager's cached scan; the panel asks for
# a fresh one (`nmcli dev wifi rescan`) when it opens and from its button.
set -uo pipefail

command -v nmcli >/dev/null 2>&1 || { echo "radio	none"; exit 0; }

if ! nmcli -t -f TYPE dev status 2>/dev/null | grep -qx wifi; then
  echo "radio	none"
else
  [[ "$(nmcli -t -f WIFI general 2>/dev/null)" == "enabled" ]] && echo "radio	on" || echo "radio	off"
fi

# Wired: TYPE:STATE:CONNECTION, connection last so a ':' in its name survives.
nmcli -t --escape no -f TYPE,STATE,CONNECTION dev status 2>/dev/null |
  awk -F: '$1 == "ethernet" && $2 == "connected" { sub(/^[^:]*:[^:]*:/, ""); print "wired\t" $0; exit }'

# Saved Wi-Fi profiles (names; NAME last for the same reason).
saved="$(nmcli -t --escape no -f TYPE,NAME con show 2>/dev/null | awk -F: '$1 == "802-11-wireless" { sub(/^[^:]*:/, ""); print }')"

# IN-USE:SIGNAL:SECURITY:SSID -- SSID last, so only the first three ':' split.
nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no 2>/dev/null |
  awk -F: -v saved="$saved" '
    BEGIN { n = split(saved, s, "\n"); for (i = 1; i <= n; i++) known[s[i]] = 1 }
    {
      inuse = ($1 == "*") ? "yes" : "no"; sig = $2 + 0; sec = $3
      ssid = $0; sub(/^[^:]*:[^:]*:[^:]*:/, "", ssid)
      gsub(/\t/, " ", ssid)
      if (ssid == "") next
      if (!(ssid in best) || sig > best[ssid]) { best[ssid] = sig; secof[ssid] = sec }
      if (inuse == "yes") used[ssid] = 1
      order[ssid] = 1
    }
    END {
      for (ssid in order)
        printf "net\t%s\t%d\t%s\t%s\t%s\n", ssid, best[ssid], secof[ssid], (ssid in used) ? "yes" : "no", (ssid in known) ? "yes" : "no"
    }'
