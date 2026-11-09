#!/usr/bin/env bash
# Everything the control centre shows, as key=value lines, in one pass -- so
# one process per refresh (every 2s, and only while the panel is open) rather
# than one per toggle.
#
#   wifi=on|off|none      ssid=<network or empty>
#   bt=on|off|none        btdev=<connected device or empty>
#   idle=on|off           (hypridle running = the screen can lock/sleep)
#   night=on|off          (hyprsunset running)
#   volume=<0-100>        muted=true|false
#   brightness=<0-100 or empty when there is no backlight>
#   dnd=true|false        notifications=<count in the bar's history>
#   cpu=<0-100>  ram=<0-100>  disk=<0-100>
#
# A missing tool just leaves its value empty (or "none"); the panel greys
# that tile out instead of erroring.
set -uo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

# CPU: two /proc/stat samples, a fifth of a second apart.
read -r _ a1 b1 c1 d1 e1 f1 g1 h1 _ < /proc/stat
sleep 0.2
read -r _ a2 b2 c2 d2 e2 f2 g2 h2 _ < /proc/stat
idle=$(( (d2 + e2) - (d1 + e1) ))
total=$(( (a2+b2+c2+d2+e2+f2+g2+h2) - (a1+b1+c1+d1+e1+f1+g1+h1) ))
(( total > 0 )) && echo "cpu=$(( (100 * (total - idle)) / total ))" || echo "cpu="

awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END { if (t > 0) printf "ram=%d\n", (100 * (t - a)) / t; else print "ram=" }' /proc/meminfo
df -P / 2>/dev/null | awk 'NR == 2 { sub("%", "", $5); print "disk=" $5 }'

if have nmcli; then
  if [[ "$(nmcli -t -f WIFI general 2>/dev/null)" == "enabled" ]]; then
    echo "wifi=on"
    echo "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print substr($0, 5); exit }')"
  else
    echo "wifi=off"; echo "ssid="
  fi
else
  echo "wifi=none"; echo "ssid="
fi

if have bluetoothctl && bluetoothctl show >/dev/null 2>&1; then
  if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
    echo "bt=on"
    echo "btdev=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)"
  else
    echo "bt=off"; echo "btdev="
  fi
else
  echo "bt=none"; echo "btdev="
fi

pgrep -x hypridle >/dev/null 2>&1 && echo "idle=on" || echo "idle=off"
pgrep -x hyprsunset >/dev/null 2>&1 && echo "night=on" || echo "night=off"

if have pamixer; then
  echo "volume=$(pamixer --get-volume 2>/dev/null)"
  echo "muted=$(pamixer --get-mute 2>/dev/null)"
else
  echo "volume="; echo "muted=false"
fi

if have brightnessctl && brightnessctl -l -c backlight 2>/dev/null | grep -q backlight; then
  echo "brightness=$(brightnessctl -m -c backlight 2>/dev/null | awk -F, 'NR == 1 { sub("%", "", $4); print $4 }')"
else
  echo "brightness="
fi

# Notifications live in the bar (its own process); ask it.
dock="$HOME/.config/hypr/dock_ipc.sh"
if [[ -x "$dock" ]]; then
  echo "dnd=$("$dock" is-dnd 2>/dev/null || echo false)"
  echo "notifications=$("$dock" count 2>/dev/null || echo 0)"
else
  echo "dnd=false"; echo "notifications=0"
fi
