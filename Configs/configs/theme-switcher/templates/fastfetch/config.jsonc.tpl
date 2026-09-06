{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "display": {
    "separator": "  ",
    "color": {
      "keys": "{{fg}}"
    },
    "key": {
      "width": 14
    }
  },
  "logo": {
    "type": "file",
    "source": "~/.config/fastfetch/jirachi.txt",
    "padding": {
      "top": 2,
      "left": 2,
      "right": 4
    }
  },
  "modules": [
    {
      "type": "title",
      "color": {
        "user": "{{red}}",
        "at": "{{fg_dim}}",
        "host": "{{pink}}"
      }
    },
    {
      "type": "custom",
      "format": "\u001b[90m ───────────────\u001b[0m"
    },
    {
      "type": "os",
      "key": " 󰣇 OS",
      "keyColor": "{{grad0}}",
      "format": "{pretty-name}"
    },
    {
      "type": "kernel",
      "key": " 󰌽 Kernel",
      "keyColor": "{{grad1}}"
    },
    {
      "type": "packages",
      "key": " 󰏖 Packages",
      "keyColor": "{{grad2}}"
    },
    {
      "type": "shell",
      "key": "  Shell",
      "keyColor": "{{grad3}}",
      "format": "{pretty-name}"
    },
    {
      "type": "wm",
      "key": "  WM",
      "keyColor": "{{grad4}}",
      "format": "{pretty-name}"
    },
    {
      "type": "cpu",
      "key": "  CPU",
      "keyColor": "{{grad5}}"
    },
    {
      "type": "gpu",
      "key": " 󰢮 GPU",
      "keyColor": "{{grad6}}"
    },
    {
      "type": "display",
      "key": " 󰍹 Screen",
      "keyColor": "{{grad7}}",
      "format": "{width}x{height} @ {refresh-rate}Hz"
    },    
    {
      "type": "memory",
      "key": "  Ram",
      "keyColor": "{{grad8}}",
      "format": "{used} / {total}"
    },
    {
      "type": "disk",
      "key": " 󰋊 Disk",
      "keyColor": "{{grad9}}",
      "format": "{size-used} / {size-total}"
    },
    {
      "type": "uptime",
      "key": " 󰔚 Uptime",
      "keyColor": "{{grad10}}"
    },
    "break",
    {
      "type": "custom",
      "key": " 󰸱 Color",
      "format": "\u001b[38;2;{{swatch1}}m󰮯 \u001b[38;2;{{swatch2}}m \u001b[38;2;{{swatch3}}m󰊠 \u001b[38;2;{{swatch4}}m󰊠 \u001b[38;2;{{swatch5}}m󰊠 \u001b[38;2;{{swatch6}}m󰊠 \u001b[38;2;{{swatch7}}m󰊠 \u001b[0m"
    }
  ]
}
