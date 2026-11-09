#!/usr/bin/env bash
# Find and stop running Quickshell BAR shells -- the one place that decides
# which `quickshell` processes count as "that config", shared by
# apply-theme.sh and hypr/start_bar.sh.
#
#   qs-stop.sh --keep NAME     stop every bar shell EXCEPT config NAME
#                              ("" = stop them all)
#   qs-stop.sh --only NAME     stop config NAME and nothing else (a restart)
#   qs-stop.sh --running NAME  exit 0 if config NAME is running, 1 if not
#   qs-stop.sh --list          print "<pid> <config>" for every instance
#
# WHY THIS EXISTS: both callers used to do `pkill -9 -f "quickshell -c laptop"`,
# a substring match against the command line. That only matches a shell
# started with exactly those words in exactly that order -- not one started
# as `qs -c laptop` (Arch's quickshell package ships `qs` as an alias), or
# `quickshell --config laptop`, `-p ~/.config/quickshell/laptop`, or with any
# flag in between (`quickshell -d -c laptop`). Such a shell survived every
# theme switch, and the new theme's bar mapped right underneath it: two bars
# stacked at the top of the screen. Here each process's argv is read from
# /proc and parsed the way Quickshell parses it, so how the shell was
# launched no longer matters.
#
# Only BAR shells are ever stopped: configs some theme names in its
# theme.json, plus any config directory carrying a colors.json (the marker
# apply-theme.sh's write_qs_colors treats as "a bar" -- it also catches a
# shell no theme names any more, like `-c hyperspace` from before
# quickshell/hyperspace/ became quickshell/bar/) -- except the desktop shell
# (NOT_BARS below), which has a colors.json but is not a bar. A theme switch
# never closes it, nor the wallpaper picker.
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
QS_BASE="$HOME/.config/quickshell"

# "<pid> <config>" per running Quickshell instance. Instances whose config
# can't be told (no -c / -p: Quickshell's default config) print an empty
# config and are never matched by name. CLI invocations of the same binary --
# `quickshell ipc ...`, `qs kill ...` -- are short-lived clients, not shells,
# and are skipped.
list_instances() {
  local dir pid arg0 config path i
  local -a argv
  for dir in /proc/[0-9]*; do
    pid="${dir#/proc/}"
    [[ "$pid" == "$$" ]] && continue
    [[ -r "$dir/cmdline" ]] || continue
    mapfile -d '' -t argv < "$dir/cmdline" 2>/dev/null || continue
    [[ ${#argv[@]} -gt 0 ]] || continue
    arg0="${argv[0]##*/}"
    [[ "$arg0" == "quickshell" || "$arg0" == "qs" ]] || continue

    config=""
    path=""
    i=1
    while [[ $i -lt ${#argv[@]} ]]; do
      arg="${argv[$i]}"
      case "$arg" in
        ipc | kill | list | log | msg) config=""; path=""; continue 2 ;;
        -c | --config) i=$((i + 1)); config="${argv[$i]:-}" ;;
        --config=*) config="${arg#--config=}" ;;
        -p | --path) i=$((i + 1)); path="${argv[$i]:-}" ;;
        --path=*) path="${arg#--path=}" ;;
      esac
      i=$((i + 1))
    done

    # -p names a directory or the shell.qml inside one; either way the
    # config's name is that directory's name, the same name -c would use
    # for a config living under ~/.config/quickshell/.
    if [[ -z "$config" && -n "$path" ]]; then
      [[ "$path" == *.qml ]] && path="$(dirname "$path")"
      config="$(basename "$path")"
    fi
    printf '%s %s\n' "$pid" "$config"
  done
}

# Configs that carry a colors.json (so the theme recolours them) but are not
# bars, and must never be stopped as one: `hykr` is the always-running
# desktop shell (launcher, clipboard, pickers, control centre). Without this,
# every theme switch's `--keep <bar>` would kill it.
NOT_BARS=(hykr)

# Every config name that is a bar (see header).
bar_configs() {
  local dir
  {
    if command -v jq >/dev/null 2>&1; then
      for dir in "$BASE"/themes/*/; do
        [[ -r "$dir/theme.json" ]] || continue
        jq -r '.quickshell.config // "laptop"' "$dir/theme.json" 2>/dev/null
      done
    fi
    for dir in "$QS_BASE"/*/; do
      if [[ -f "$dir/colors.json" ]]; then basename "$dir"; fi
    done
  } | grep -v '^null$' | grep -v '^$' | grep -vxF -f <(printf '%s\n' "${NOT_BARS[@]}") | sort -u
}

# SIGKILL, then wait (up to ~2s) until the processes are really gone. A plain
# SIGTERM followed straight by the replacement's launch raced: the old shell
# hadn't released its layer-shell surface yet, and both bars ended up mapped.
kill_and_wait() {
  local pid
  [[ $# -gt 0 ]] || return 0
  kill -9 "$@" >/dev/null 2>&1 || true
  for _ in {1..20}; do
    local alive=0
    for pid in "$@"; do
      if [[ -d "/proc/$pid" ]]; then alive=1; break; fi
    done
    [[ $alive -eq 0 ]] && return 0
    sleep 0.1
  done
}

mode="${1:-}"
name="${2:-}"
pids=()

case "$mode" in
  --list)
    list_instances
    ;;
  --running)
    [[ -n "$name" ]] || exit 2
    while read -r pid config; do
      [[ "$config" == "$name" ]] && exit 0
    done < <(list_instances)
    exit 1
    ;;
  --only)
    [[ -n "$name" ]] || exit 2
    while read -r pid config; do
      [[ "$config" == "$name" ]] && pids+=("$pid")
    done < <(list_instances)
    kill_and_wait "${pids[@]}"
    ;;
  --keep)
    mapfile -t bars < <(bar_configs)
    while read -r pid config; do
      [[ -n "$config" && "$config" != "$name" ]] || continue
      for b in "${bars[@]}"; do
        if [[ "$config" == "$b" ]]; then pids+=("$pid"); break; fi
      done
    done < <(list_instances)
    kill_and_wait "${pids[@]}"
    ;;
  *)
    echo "Usage: qs-stop.sh --keep NAME | --only NAME | --running NAME | --list" >&2
    exit 2
    ;;
esac
exit 0
