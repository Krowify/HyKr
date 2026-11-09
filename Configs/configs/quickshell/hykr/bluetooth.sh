#!/usr/bin/env bash
# Bluetooth state for the desktop shell's Bluetooth panel, tab-separated:
#
#   power  on|off|none
#   dev    <mac>  <name>  <paired yes|no>  <connected yes|no>  <icon>  <battery % or empty>
#
# Every device bluez knows: paired ones, and anything found while the panel
# is scanning. Discovered devices that never sent a name (shown by bluez as
# their address) are left out -- a scan near other people's phones and
# beacons is otherwise a wall of addresses.
set -uo pipefail

command -v bluetoothctl >/dev/null 2>&1 || { echo "power	none"; exit 0; }

show="$(bluetoothctl show 2>/dev/null)"
if [[ -z "$show" ]]; then
  echo "power	none"   # no adapter, or bluetoothd not running
  exit 0
fi
grep -q 'Powered: yes' <<<"$show" && echo "power	on" || echo "power	off"

bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
  [[ "$mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]] || continue
  info="$(bluetoothctl info "$mac" 2>/dev/null)"
  paired="$(sed -n 's/^\s*Paired: //p' <<<"$info" | head -n1)"
  connected="$(sed -n 's/^\s*Connected: //p' <<<"$info" | head -n1)"
  icon="$(sed -n 's/^\s*Icon: //p' <<<"$info" | head -n1)"
  battery="$(sed -n 's/^\s*Battery Percentage: .*(\([0-9]*\))/\1/p' <<<"$info" | head -n1)"
  # bluez names an unnamed device after its address (with '-' for ':').
  [[ "$paired" != "yes" && ( -z "$name" || "$name" == "${mac//:/-}" ) ]] && continue
  printf 'dev\t%s\t%s\t%s\t%s\t%s\t%s\n' "$mac" "${name//$'\t'/ }" "${paired:-no}" "${connected:-no}" "$icon" "$battery"
done
