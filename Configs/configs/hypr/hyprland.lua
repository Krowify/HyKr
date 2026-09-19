-- Monitors: per-machine, so they live OUTSIDE this tracked file.
--
-- This block used to pin HDMI-A-1 / DP-2 / DP-3 / eDP-1 by name, with
-- explicit modes, positions and rotations, straight out of the author's
-- `hyprctl monitors`. Those names are not distinctive: HDMI-A-1 is the
-- first HDMI output and eDP-1 the internal panel on nearly any machine, so
-- anyone else installing HyKr whose output happened to match got a display
-- rotated 90 degrees, positioned at 0x370, at a mode their panel may not
-- even support -- on first login, before they had a terminal open to fix
-- it. The catch-all below never helped, because the explicit rules match
-- first.
--
-- Put your own layout in ~/.config/hypr/monitors.lua (gitignored). The way to
-- create one is not to write it by hand: arrange the displays how you like,
-- then freeze the live layout with
--
--     ~/HyKr/Scripts/snapshot_monitors.sh
--
-- monitors.lua.example covers the by-hand route and explains why `scale` and
-- `transform` in particular are worth pinning.
--
-- With no monitors.lua present the catch-all below is a working default, but
-- note that its `scale = "auto"` means a DPI-derived (often fractional) scale
-- rather than whatever you had -- the usual cause of "my scaling changed and
-- I do not know why".
--
-- pcall, not a bare require: require() on a missing module is a hard error
-- that takes down the whole config -- every keybind with it -- which is
-- exactly what this file already guards against for plugins via
-- is_plugin_loaded(). Same reasoning, same treatment.
local ok_monitors, monitors_err = pcall(require, "monitors")
if not ok_monitors then
    -- Not found is the normal, supported case and stays quiet. A monitors.lua
    -- that exists but has a syntax error is not, and silently swallowing that
    -- would look identical to "my monitor config does nothing" -- so that one
    -- goes to the Hyprland log (`journalctl --user -u hyprland`, or the
    -- terminal Hyprland was started from).
    --
    -- Plain `print`, and string.find with plain=true: this is the file's
    -- safety net, so it must not itself depend on an hl.* helper or on Lua
    -- pattern escaping being right.
    local msg = tostring(monitors_err)
    if not string.find(msg, "module 'monitors' not found", 1, true) then
        print("HyKr: ~/.config/hypr/monitors.lua failed to load: " .. msg)
    end
end

-- Fallback for any monitor monitors.lua did not name (and, with no
-- monitors.lua at all, for every monitor).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Caps Lock does nothing when pressed -- a Wayland/libinput setting
-- (xkb_options), not the old X11 setxkbmap approach.
--
-- natural_scroll lives in the touchpad sub-category on purpose, NOT as a
-- bare input:natural_scroll: the global key wins over the per-device one
-- and would flip the desktop's mouse wheel too (hyprwm/Hyprland#2458).
-- Nested here it only ever reaches touchpads, so it's a silent no-op on
-- the desktop and needs no has_trackpad() gate (which isn't defined until
-- further down this file anyway).
hl.config({
    input = {
        kb_options = "caps:none",

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Pywal colors for window borders. wal -i renders
-- Configs/configs/wal/templates/colors-hyprland.lua into ~/.cache/wal/,
-- and apply_wallpaper.sh/wallpaper.sh copy it into ~/.config/hypr/ right
-- after, same as they already do for kitty's current-theme.conf --
-- Lua's require() only resolves modules under the config root, so a file
-- that has to be reachable this way can't stay in ~/.cache.
-- pcall, not a bare require -- and this is the important part.
--
-- Both of these files are GENERATED (apply-theme.sh writes generated-theme.lua;
-- apply-theme.sh and apply_wallpaper.sh write colors-hyprland.lua) and neither
-- is tracked by git. A bare require() on a missing module is a hard error that
-- aborts this entire file: no window rules, no autostart, and no keybinds --
-- which looks like "my whole theme reverted, the bar is wrong and the wallpaper
-- is blank", because the autostart that launches the bar and awww-daemon never
-- ran. One missing file, every symptom at once, and nothing on screen to say so.
--
-- That is not hypothetical: link_dots.sh's link_dot() moves a real ~/.config/hypr
-- aside and re-symlinks it to the repo, and both of these are untracked, so they
-- do not come back.
--
-- Degrade instead. hypr/restore_theme.sh runs from the autostart below and
-- re-renders them properly; this just has to keep the config loading until it
-- gets the chance.
local function load_generated(mod, what)
    local ok, err = pcall(require, mod)
    if not ok then
        print("HyKr: ~/.config/hypr/" .. mod .. ".lua did not load -- " .. what)
        print("HyKr:   " .. tostring(err))
        print("HyKr:   restore_theme.sh will re-render it; or run: ~/.config/theme-switcher/apply-theme.sh <theme>")
    end
    return ok
end

load_generated("colors-hyprland", "border colours fall back to built-in defaults")

-- var_color4 / var_backgroundCol come from colors-hyprland.lua and are read
-- further down. If it did not load they are nil, and passing nil to
-- col.active_border is itself a config error -- so give them something valid.
var_color4 = var_color4 or "0xff7aa2f7"
var_backgroundCol = var_backgroundCol or "0xff141414"

-- theme-switcher's gaps/border_size/rounding/opacity/shadow/blur/layerrules,
-- regenerated by apply-theme.sh from each theme's theme.json. Missing means
-- Hyprland's own defaults for those -- a plain desktop, but a working one.
load_generated("generated-theme", "gaps/rounding/blur fall back to Hyprland defaults")

-- Route Qt apps (dolphin, kate) through qt6ct-kde (pkg_core.lst) so they
-- pick up the color scheme apply-theme.sh generates at
-- ~/.config/qt6ct/colors/hykr.conf. Plain qt6ct doesn't style KDE
-- Frameworks apps like dolphin correctly -- needs the qt6ct-kde fork,
-- which keeps the same env value and config path/format.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Cursor theme. gtk-{3,4}.0/settings.ini already set
-- gtk-cursor-theme-name=Bibata-Modern-Classic, but that only reaches GTK
-- apps -- Hyprland's own pointer, and every Qt/Wayland-native client, read
-- XCURSOR_THEME/XCURSOR_SIZE from the environment instead. Without these the
-- installed cursor theme (illogical-impulse-bibata-modern-classic-bin, in
-- pkg_core.lst) applied to roughly half the desktop and the rest fell back
-- to default Adwaita.
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

-- Pywal border colors always win over the active theme's border colors,
-- same as every other "last write wins" surface in this repo (kitty,
-- starship, spicetify) -- var_color4/var_backgroundCol come from the
-- require("colors-hyprland") above.
hl.config({
    general = {
        col = {
            active_border = var_color4,
            inactive_border = var_backgroundCol,
        },
    },
})

-- --------------------------------------------------- // Trackpad gestures & Mission Control
-- hyprexpo was retired from the official hyprwm/hyprland-plugins repo
-- (github.com/hyprwm/hyprland-plugins/pull/663) -- sandwichfarm/hyprexpo is
-- the actively maintained continuation this repo tracks instead. Both it
-- and hyprgrass are hyprpm-managed plugins (installed by
-- Scripts/extra/setup_hypr_gestures.sh), not pacman packages, so neither
-- shows up in pkg_core.lst/pkg_extra.lst.
local function has_trackpad()
    local f = io.open("/proc/bus/input/devices", "r")
    if not f then return false end
    local contents = f:read("*a")
    f:close()
    return contents:lower():find("touchpad") ~= nil
end

-- `hyprpm enable <name>` can succeed while the actual build fails (seen in
-- practice: hyprgrass's -backlight/-pulse sub-plugins failing to compile
-- while hyprgrass itself, or hyprexpo, build fine) -- hl.config() for a
-- plugin category Hyprland doesn't recognize because it never actually
-- loaded is a hard parse-time error that takes down the WHOLE config file,
-- every keybind included. Check hl.get_loaded_plugins() before touching
-- any plugin.* config/function so one failed build can't do that again.
local function is_plugin_loaded(name)
    for _, plugin in ipairs(hl.get_loaded_plugins()) do
        if plugin.name == name then return true end
    end
    return false
end

-- hyprexpo works fine driven by mouse/keyboard alone, so its config and
-- O keybind (below, with var_mainMod) always load -- only the touchpad
-- swipe *trigger* for it is hardware-gated below.
if is_plugin_loaded("hyprexpo") then
    hl.config({
        plugin = {
            hyprexpo = {
                columns = 3,
                gaps_in = 5,
                gaps_out = 10,
                workspace_method = "center current",
                gesture_distance = 200,
                cancel_key = "escape",
                show_cursor = 1,
                keynav_enable = 1,
            },
        },
    })
end

-- Desktop has no touchpad, laptop does -- same repo, same file, no
-- per-machine config branch needed.
if has_trackpad() then
    -- Native 3-finger horizontal swipe between workspaces -- built into
    -- Hyprland itself, no plugin required
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

    if is_plugin_loaded("hyprexpo") then
        -- 4-finger swipe up opens the hyprexpo overview -- hyprexpo handles
        -- this gesture itself, no need to route it through hyprgrass
        hl.plugin.hyprexpo.gesture({ fingers = 4, direction = "up", action = "expo" })
    end

    if is_plugin_loaded("hyprgrass") then
        -- hyprgrass covers the gestures neither native `hl.gesture` nor
        -- hyprexpo's own gesture hook do
        hl.config({
            plugin = {
                hyprgrass = {
                    sensitivity = 1.0,
                    long_press_delay = 400,
                    resize_on_border_long_press = true,
                    edge_margin = 10,
                },
            },
            gestures = {
                workspace_swipe_touch = true,
                workspace_swipe_cancel_ratio = 0.15,
            },
        })

        hl.plugin.hyprgrass.bind({
            pattern = { kind = "tap", fingers = 3 },
            action = hl.dsp.window.float(),
        })
        hl.plugin.hyprgrass.bind({
            pattern = { kind = "pinch", fingers = 3, direction = "pinchin" },
            action = hl.dsp.window.close(),
        })
    end
end

-- Autostart
hl.on("hyprland.start", function()
    -- Secret storage (VS Code, browsers, etc. need this via libsecret --
    -- Hyprland has no keyring daemon of its own, unlike GNOME/KDE sessions)
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
    -- Polkit agent -- Hyprland has no polkit agent of its own either, so
    -- privilege-escalation prompts (mounting a drive from Dolphin, some
    -- NetworkManager/Bluetooth actions) silently fail or hang without one.
    hl.exec_cmd("hyprpolkitagent")
    -- Bar + notification daemon, picked from the ACTIVE theme rather
    -- than hardcoded. Most themes use the waybar+swaync pair; the Laptop
    -- theme replaces both with one Quickshell process ("bar":
    -- "quickshell-dock" in its theme.json, which apply-theme.sh honours).
    -- Starting waybar unconditionally here meant it came back on every
    -- login even under the Laptop theme -- stacked on top of the
    -- Quickshell dock -- and swaync doubled its notifications.
    -- The `[ -x ... ] ||` guard covers an install whose ~/.config/hypr
    -- apply-theme.sh already de-symlinked into a real copy (it does that
    -- on the first theme apply) before start_bar.sh existed: there the
    -- script isn't present until link_dots.sh is re-run, and without the
    -- fallback that login would come up with no bar at all.
    -- Re-assert what the theme switcher last set: the wallpaper (nothing else
    -- in this autostart ever did -- awww-daemon was started and then simply
    -- hoped to restore its own cache) and, if a generated file has gone
    -- missing, the whole theme. Runs BEFORE start_bar.sh on purpose: when it
    -- does re-apply a theme, apply-theme.sh brings up that theme's bar itself,
    -- and start_bar.sh below then finds it already running and no-ops.
    hl.exec_cmd("[ -x ~/.config/hypr/restore_theme.sh ] && ~/.config/hypr/restore_theme.sh")
    hl.exec_cmd("[ -x ~/.config/hypr/start_bar.sh ] && ~/.config/hypr/start_bar.sh || { waybar & swaync & }")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("wal -R")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("mkdir -p ~/Pictures/Screenshots")
end)

local var_terminal = "kitty"
local var_mainMod = "SUPER"
local var_menu = "wofi --show drun -n"
local var_fileManager = "dolphin"
local var_editor = "kate"
local var_browser = "brave"

-- Dropdown terminal on its own special workspace
hl.on("hyprland.start", function()
    hl.exec_cmd("[workspace special:dropterm silent] " .. var_terminal .. " --class dropterm")
end)
hl.window_rule({ match = { class = "^(dropterm)$" }, float = true })
hl.window_rule({ match = { class = "^(dropterm)$" }, size = "80% 60%" })

-- Dolphin: match the rest of the theming at 75% opacity
hl.window_rule({ match = { class = "^(org\\.kde\\.dolphin)$" }, opacity = "0.75 0.75" })

-- --------------------------------------------------- // Terminal
hl.bind(var_mainMod .. " + RETURN", hl.dsp.exec_cmd(var_terminal))
hl.bind(var_mainMod .. " + ALT + T", hl.dsp.workspace.toggle_special("dropterm"))

-- --------------------------------------------------- // Close, force-kill, exit
hl.bind(var_mainMod .. " + Q", hl.dsp.window.close())
hl.bind(var_mainMod .. " + ALT + F4", hl.dsp.exec_cmd("kill -9 $(hyprctl activewindow -j | jq -r .pid)"))
hl.bind(var_mainMod .. " + DELETE", hl.dsp.exit())
hl.bind(var_mainMod .. " + ESCAPE", hl.dsp.exec_cmd("wlogout"))
-- lock.sh, not hyprlock directly: it guards against a second instance and,
-- once you unlock, brings back the bar the active theme wants (a Quickshell
-- dock does not always survive hyprlock's session-lock surface). Every other
-- way of locking -- wlogout, quick_settings.sh, hypridle's lock_cmd, and so
-- `loginctl lock-session` too -- goes through the same script.
hl.bind(var_mainMod .. " + L", hl.dsp.exec_cmd("~/.config/hypr/lock.sh"))

-- --------------------------------------------------- // Toggle
hl.bind(var_mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var_mainMod .. " + G", hl.dsp.group.toggle())
-- dwindle's "togglesplit" message is dead in Hyprland 0.56.2 -- hl.dsp.layout
-- fires clean (confirmed via `hyprctl dispatch 'hl.dsp.layout("togglesplit")'`,
-- returns ok, no error) but the compositor silently drops that specific
-- message (github.com/hyprwm/Hyprland/issues/15106, "togglesplit does not
-- exist"); "swapsplit" on the same call path works fine, so that's what's
-- bound here until upstream restores togglesplit or ships a replacement.
hl.bind(var_mainMod .. " + J", hl.dsp.layout("swapsplit"))
hl.bind(var_mainMod .. " + M", hl.dsp.exec_cmd("pkill -x -f 'quickshell -c hykr' || quickshell -c hykr"))
-- Toggles whichever bar the active theme actually runs (waybar, or the
-- Laptop theme's Quickshell dock) -- the old "pkill waybar || waybar"
-- could only ever start waybar, resurrecting it under the Laptop theme.
hl.bind(var_mainMod .. " + CTRL + B", hl.dsp.exec_cmd("~/.config/hypr/start_bar.sh --toggle"))
-- Notification center. The Laptop theme runs no swaync (its Quickshell
-- dock carries its own notification daemon and center), so this bind was
-- simply dead under that theme. Ask the dock over IPC first; under every
-- waybar theme no laptop shell is running, that call fails, and
-- swaync-client runs exactly as before.
-- dock_ipc.sh resolves the ACTIVE theme's Quickshell config (Laptop's dock,
-- Hyperspace's, or none) and falls back to swaync-client under the waybar
-- themes. It replaces a hardcoded `quickshell -c laptop ipc call ...` that
-- did nothing at all under any other Quickshell theme.
hl.bind(var_mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/dock_ipc.sh toggle-notifications"))
hl.bind(var_mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 5000"))
hl.bind(var_mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("pkill hypridle || hypridle"))
hl.bind(var_mainMod .. " + S", hl.dsp.exec_cmd("~/.config/hypr/quick_settings.sh"))
hl.bind(var_mainMod .. " + O", function()
    if is_plugin_loaded("hyprexpo") then hl.plugin.hyprexpo.expo("toggle") end
end)

-- --------------------------------------------------- // Launchers and apps
hl.bind(var_mainMod .. " + TAB", hl.dsp.exec_cmd(var_menu))
hl.bind(var_mainMod .. " + E", hl.dsp.exec_cmd(var_fileManager))
hl.bind(var_mainMod .. " + C", hl.dsp.exec_cmd(var_editor))
hl.bind(var_mainMod .. " + B", hl.dsp.exec_cmd(var_browser))
hl.bind(var_mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- --------------------------------------------------- // Workspace and theming
hl.bind(var_mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(var_mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(var_mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))
hl.bind(var_mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pkill -9 -x -f 'quickshell -c wallpaper-picker'; ~/.config/quickshell/wallpaper-picker/launch.sh"))
hl.bind(var_mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.config/theme-switcher/theme-picker.sh"))

-- --------------------------------------------------- // Alt
hl.bind("ALT + P", hl.dsp.window.pseudo())
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))

-- --------------------------------------------------- // Window movement
hl.bind(var_mainMod .. " + CTRL + H", hl.dsp.group.prev())
hl.bind(var_mainMod .. " + CTRL + L", hl.dsp.group.next())
hl.bind(var_mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(var_mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }))
hl.bind(var_mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }))
hl.bind(var_mainMod .. " + CTRL + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(var_mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(var_mainMod .. " + CTRL + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(var_mainMod .. " + CTRL + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(var_mainMod .. " + SHIFT + comma", hl.dsp.window.move({ monitor = "-1" }))
hl.bind(var_mainMod .. " + SHIFT + period", hl.dsp.window.move({ monitor = "+1" }))

-- Hold-to-move / hold-to-resize (arrows; Escape to exit)
hl.bind(var_mainMod .. " + Z", hl.dsp.submap("move"))
hl.define_submap("move", function()
    hl.bind("right", hl.dsp.window.move({ x = 30, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.move({ x = -30, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.move({ x = 0, y = -30, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.move({ x = 0, y = 30, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    -- The global Super+Shift+R escape hatch is dead while a submap is
    -- active, so every submap re-binds it. See the note below.
    hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.submap("reset"))
end)
hl.bind(var_mainMod .. " + X", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    -- The global Super+Shift+R escape hatch is dead while a submap is
    -- active, so every submap re-binds it. See the note below.
    hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.submap("reset"))
end)

-- Escape hatch: a submap that isn't torn down cleanly leaves every bind
-- outside it dead -- Super+Return included -- until the submap is forced
-- back to global. hyprexpo's keynav submap is the usual culprit (upstream
-- sandwichfarm/hyprexpo #99, #39), but `move`/`resize` above can strand
-- you the same way if their Escape is missed.
--
-- This global copy only helps if you are NOT currently in a submap, which
-- is exactly when you don't need it -- so each submap re-binds
-- Super+Shift+R itself. This one stays for the case where a submap was
-- exited but binds still feel wrong.
--
-- `hyprctl reload` does NOT clear a stuck submap. Confirmed the hard way:
-- a session stuck in `move` still reported `hyprctl submap` -> move after
-- a reload that returned ok. If every bind is dead and no submap's
-- Super+Shift+R reaches you, recover from an open terminal with
--
--     hyprctl dispatch 'hl.dsp.submap("reset")'
--
-- Note the Lua quoting: with a Lua config, hyprctl interpolates the
-- argument straight into `return hl.dispatch(...)`, so a bare
-- `hyprctl dispatch submap reset` is a Lua syntax error, not a dispatch.
hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.submap("reset"))

for i = 1, 10 do
    local key = i % 10
    hl.bind(var_mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(var_mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(var_mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Mission Control keyboard navigation while the hyprexpo overview is open
-- (hyprexpo enters this submap itself via plugin:hyprexpo:keynav_enable)
hl.define_submap("hyprexpo", function()
    hl.bind("h", function() hl.plugin.hyprexpo.kb_focus("left") end)
    hl.bind("l", function() hl.plugin.hyprexpo.kb_focus("right") end)
    hl.bind("k", function() hl.plugin.hyprexpo.kb_focus("up") end)
    hl.bind("j", function() hl.plugin.hyprexpo.kb_focus("down") end)
    hl.bind("return", function() hl.plugin.hyprexpo.kb_confirm() end)
    hl.bind("escape", function() hl.plugin.hyprexpo.expo("cancel") end)
    -- Same escape hatch. This submap is the one that actually leaks
    -- (upstream #99, #39): cancelling the overview is what normally
    -- exits it, so when the overview closes by some other path this
    -- bind is the only way back to global without a terminal.
    hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.submap("reset"))
end)

-- --------------------------------------------------- // Screenshot
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(var_mainMod .. " + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(var_mainMod .. " + ALT + P", hl.dsp.exec_cmd("grim -o \"$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')\" - | wl-copy"))
hl.bind(var_mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png"))

-- --------------------------------------------------- // Other (hardware, media, no modifier)
hl.bind("SHIFT + F11", hl.dsp.window.fullscreen())
hl.bind("F10", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("F12", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })

-- The same three actions on the XF86 media keycodes. The F10/F11/F12 binds
-- above are what the desktop's keyboard sends; a laptop's dedicated volume
-- keys emit XF86AudioMute / XF86AudioLowerVolume / XF86AudioRaiseVolume
-- instead (KEY_MUTE / KEY_VOLUMEDOWN / KEY_VOLUMEUP at the libinput level),
-- which nothing here bound -- so on the laptop the volume keys did nothing
-- at all. Binding both sets keeps one file working on both machines, the
-- same way has_trackpad() does for gestures, just resolved at bind time
-- rather than at runtime: a keycode the keyboard never emits is simply a
-- bind that never fires.
--
-- Same pamixer/step/flags as above deliberately, so both sets of keys
-- behave identically. locked = true keeps them working on the hyprlock
-- screen; repeating = true lets holding the key ramp.
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })

-- --------------------------------------------------- // Laptop function row
-- The rest of the MSI's Fn row. Each of these is a standard XF86 keysym
-- that libinput maps from the matching KEY_* code, so they cost nothing on
-- the desktop: a keycode that keyboard never emits is just a bind that
-- never fires -- same reasoning as the XF86Audio* block above.
--
-- What is NOT guaranteed is that a given laptop emits all of them. Several
-- MSI Fn keys are swallowed by the EC and never reach the compositor at
-- all (the keyboard backlight especially). Confirm what yours actually
-- sends with:
--     sudo libinput debug-events --show-keycodes
-- and check the KEY_* name against the keysym bound here.
--
-- locked = true on brightness and backlight so they still work on the
-- hyprlock screen -- adjusting a too-dim screen while locked is exactly
-- when you need them.

-- F9 / F10 -- screen brightness. brightnessctl is already in pkg_core.lst
-- (listed for the quick-settings slider). 5% steps match the volume keys.
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q set +5%"), { locked = true, repeating = true })

-- F5 -- mic mute. pamixer's --default-source is the input-side counterpart
-- of the -t above, so this stays on the one audio CLI the rest of the row
-- uses rather than adding wpctl.
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })

-- F6 -- bluetooth. Same toggle quick_settings.sh already offers from its
-- wofi menu, so the key and the menu can't disagree.
hl.bind("XF86Bluetooth", hl.dsp.exec_cmd("bluetoothctl power \"$(bluetoothctl show | grep -q 'Powered: yes' && echo off || echo on)\""))

-- F12 -- airplane mode. Via the helper because a bare `rfkill block all`
-- needs root (/dev/rfkill is root-only on stock Arch) and would just fail
-- silently on a keypress; the helper uses nmcli + bluetoothctl, which both
-- work as the logged-in user through polkit.
hl.bind("XF86RFKill", hl.dsp.exec_cmd("~/.config/hypr/fn_keys.sh airplane"))

-- F4 and F8 -- both need a device name looked up first, so they go through
-- the helper rather than inlining a pipeline here. It always exits 0 and
-- explains itself on stderr when the device isn't there.
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("~/.config/hypr/fn_keys.sh touchpad"))
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd("~/.config/hypr/fn_keys.sh kbd-light toggle"), { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/fn_keys.sh kbd-light down"), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/fn_keys.sh kbd-light up"), { locked = true, repeating = true })

-- --------------------------------------------------- // Mouse
hl.bind(var_mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(var_mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
