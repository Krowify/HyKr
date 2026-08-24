/* Minimal: near-black translucent pills, white text, a single restrained
   accent for the active workspace. Modeled on 43PR/dotfiles' waybar (dark
   rgba(20,20,20) pill modules, pure white text, one muted accent). */

* {
  border: none;
  min-height: 0;
  font-family: {{font_family}};
  font-size: 12px;
  margin: 0;
}

window#waybar {
  background: transparent;
}

#waybar {
  background: transparent;
  margin: 0;
}

.modules-center {
  background: alpha({{bg}}, 0.5);
  color: {{fg}};
  margin: 0;
  padding: 6px 6px;
  border-radius: 10px;
}

.modules-left,
.modules-right {
  background: transparent;
}

#pulseaudio,
#network,
#bluetooth,
#clock,
#tray,
#custom-notification {
  background: transparent;
  color: {{fg}};
  padding: 0 0 0 10px;
  margin: 0;
}

#custom-notification {
  padding: 0 10px 0 10px;
}

#clock {
  font-weight: bold;
}

/* Workspace container */
#workspaces {
  padding: 0 4px;
}

/* Default workspaces (inactive) */
#workspaces button {
  min-width: 10px;
  min-height: 10px;

  margin: 0 2px;
  padding: 0 4px;

  background: transparent;
  border: 2px solid {{surface2}};
  border-radius: 8px;

  color: {{fg}};
}

/* Active workspace: the one deliberate accent in an otherwise monochrome bar */
#workspaces button.active {
  min-width: 32px;
  min-height: 12px;

  background: {{accent}};
  border-radius: 8px;
  border: none;

  color: {{bg}};
}

#workspaces button:hover {
  background: {{surface}};
}

#workspaces button.active:hover {
  background: {{accent}};
}

/* Subtle separators inside the pill */
#pulseaudio,
#network,
#bluetooth,
#clock,
#tray,
#custom-notification {
  border-left: 1px solid {{surface}};
  padding-left: 12px;
}
