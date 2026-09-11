/* Minimal: ported from 43PR/dotfiles' actual waybar/style.css
   (github.com/43PR/dotfiles) -- three near-black translucent pills
   (left/center/right), plain white text, red only for a critical
   temperature reading. */

* {
  font-family: {{font_family}}, "Symbols Nerd Font Mono", monospace;
  font-size: 11px;
  min-height: 0;
}

window#waybar {
  min-height: 10px;
  background-color: transparent;
  color: {{fg}};
}

/* LEFT */
.modules-left {
  background-color: alpha({{bg}}, 0.5);
  border-radius: 10px;
  margin: 4px 0 2px 6px;
}

/* CENTER */
.modules-center {
  background-color: alpha({{bg}}, 0.5);
  border-radius: 10px;
  margin: 4px 0 2px;
}

/* RIGHT */
.modules-right {
  background-color: alpha({{bg}}, 0.5);
  border-radius: 10px;
  margin: 4px 6px 2px 0;
}

/* Module spacing */
#cpu,
#memory,
#custom-gpu,
#clock,
#pulseaudio,
#mpris,
#custom-power,
#temperature,
#battery {
  padding: 0 10px;
  margin: 0 2px;
  color: {{fg}};
}

/* Power */
#custom-power {
  color: {{fg}};
  font-size: 15px;
  margin-right: 10px;
}

/* MPRIS */
#mpris {
  min-width: 0;
}

/* Clock */
#clock {
  font-weight: bold;
}

/* Temperature */
#temperature.critical {
  color: {{red}};
}

/* Battery */
#battery.warning {
  color: {{yellow}};
}

#battery.critical {
  color: {{red}};
}

/* Tooltip */
tooltip {
  background-color: alpha({{bg}}, 0.4);
  color: {{fg}};
  font-weight: bold;
  border: 1px solid rgba(255, 255, 255, 0);
  border-radius: 25px;
}

tooltip label {
  color: {{fg}};
  font-size: 11px;
  padding: 0;
  margin: 0;
}

/* Interactive hover effect */
#cpu,
#memory,
#custom-gpu,
#temperature,
#battery,
#clock,
#pulseaudio,
#mpris,
#custom-power {
  transition: font-size 0.15s ease;
}

#cpu:hover,
#memory:hover,
#custom-gpu:hover,
#temperature:hover,
#battery:hover,
#clock:hover,
#pulseaudio:hover,
#mpris:hover,
#custom-power:hover {
  font-size: 14px;
}
