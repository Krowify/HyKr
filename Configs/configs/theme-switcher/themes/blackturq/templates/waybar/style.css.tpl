/* Blackturq — flat, full-width bar. Palette comes from this theme's
 * colors.json via apply-theme.sh; every colour below is a placeholder, so
 * editing colors.json restyles the bar with no change to this file.
 *
 * Deliberately NOT a centre island like Graphite/Hyperspace: upstream
 * Blackturq runs a flat bar with the module groups spaced to the edges,
 * and that is the look this theme exists to reproduce. */

@define-color background {{bg}};
@define-color foreground {{green}};
@define-color accent {{accent}};
@define-color muted {{overlay}};
@define-color red {{red}};
/* Upstream Blackturq tints battery.warning pale blue (#A9D1D7). Using the
 * palette's yellow instead: a warning state that reads as "cool" is the
 * one place faithfulness costs legibility. */
@define-color warning {{yellow}};
@define-color border_bg {{surface}};

* {
  border: none;
  border-radius: 10px;
  min-height: 0;
  margin: 0;
  font-family: {{font_family}};
  font-size: 10px;
}

window#waybar {
  background-color: @background;
  color: @foreground;
}

.modules-left {
  margin-left: 8px;
}

.modules-right {
  margin-right: 8px;
}

/* Workspaces — `all: initial` strips GTK's default button chrome, which is
 * what gives these the bare dot look rather than pill buttons. */
#workspaces button {
  all: initial;
  min-width: 9px;
  padding: 0 6px;
  margin: 0 1.5px;
  color: @muted;
}

#workspaces button.active {
  opacity: 0.8;
  color: @accent;
}

#workspaces button.urgent {
  color: @red;
}

#battery,
#pulseaudio,
#network,
#bluetooth,
#clock,
#mpris {
  min-width: 12px;
  padding: 0 5px;
  margin: 0;
}

#custom-notification,
#custom-power {
  min-width: 12px;
  padding-left: 18px;
  padding-right: 5px;
  margin: 0;
}

#custom-power {
  color: @red;
}

#tray {
  padding: 0 2px;
  margin: 0;
}

#mpris {
  color: @muted;
}

#battery.warning {
  color: @warning;
}

#battery.critical {
  color: @red;
}

tooltip {
  padding: 2px;
  background-color: @background;
  border: 1px solid @border_bg;
}

tooltip label {
  color: {{fg}};
}

.hidden {
  opacity: 0;
}
