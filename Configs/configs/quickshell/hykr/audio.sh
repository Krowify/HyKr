#!/usr/bin/env bash
# Audio state for the desktop shell's audio panel, one line per thing,
# tab-separated:
#
#   sink    <name>  <description>  <volume 0-150>  <muted true|false>  <default true|false>
#   source  <name>  <description>  <volume>        <muted>             <default>
#   app     <index> <application name>  <volume>   <muted>             <what it's playing>
#
# From pactl's JSON output (pipewire-pulse speaks the same protocol), so a
# description with spaces or tabs can't split a field. Sources exclude the
# ".monitor" loopbacks of each output, which aren't microphones.
set -uo pipefail

command -v pactl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

def_sink="$(pactl get-default-sink 2>/dev/null)"
def_source="$(pactl get-default-source 2>/dev/null)"

# Average of the channels' percentages; tabs/newlines in names flattened.
filter='
  def clean: tostring | gsub("[\t\n]"; " ");
  def vol: ([.volume[]?.value_percent? // empty | rtrimstr("%") | tonumber] | if length > 0 then (add / length | round) else 0 end);
'

pactl -f json list sinks 2>/dev/null | jq -r --arg def "$def_sink" "$filter"'
  .[] | ["sink", (.name | clean), ((.description // .name) | clean), (vol | tostring), (.mute | tostring), ((.name == $def) | tostring)] | join("\t")'

pactl -f json list sources 2>/dev/null | jq -r --arg def "$def_source" "$filter"'
  .[] | select((.name | endswith(".monitor")) | not)
  | ["source", (.name | clean), ((.description // .name) | clean), (vol | tostring), (.mute | tostring), ((.name == $def) | tostring)] | join("\t")'

pactl -f json list sink-inputs 2>/dev/null | jq -r "$filter"'
  .[] | ["app", (.index | tostring),
         ((.properties["application.name"] // .properties["application.process.binary"] // "Unknown") | clean),
         (vol | tostring), (.mute | tostring),
         ((.properties["media.name"] // "") | clean)] | join("\t")'
