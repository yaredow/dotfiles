{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "file",
        "source": "~/.config/fastfetch/logo.txt",
        "color": {
            "1": "{{blue}}"
        },
        "padding": {
            "top": 2,
            "right": 3,
            "left": 1
        }
    },
    "display": {
        "separator": " ",
        "color": {
            "keys": "{{blue}}",
            "title": "{{mauve}}",
            "output": "{{text}}",
            "separator": "{{overlay0}}"
        },
        "size": {
            "maxPrefix": "MB",
            "ndigits": 0,
            "spaceBeforeUnit": "never"
        },
        "freq": {
            "ndigits": 3,
            "spaceBeforeUnit": "never"
        }
    },
    "modules": [
        "title",
        "separator",
        "break",
        {
            "type": "custom",
            "format": "┌──────────────────────Hardware──────────────────────┐",
            "formatColor": "{{overlay0}}"
        },
        {
            "type": "host",
            "key": "  󰇮 PC",
            "keyColor": "{{blue}}"
        },
        {
            "type": "cpu",
            "key": "│ ├󰒼",
            "showPeCoreCount": true,
            "keyColor": "{{blue}}"
        },
        {
            "type": "gpu",
            "key": "│ ├󰅪",
            "detectionMethod": "pci",
            "format": "{name}",
            "keyColor": "{{blue}}"
        },
        {
            "type": "display",
            "key": "│ ├󱄄",
            "compactType": "original",
            "keyColor": "{{blue}}"
        },
        {
            "type": "disk",
            "key": "│ ├󰋊",
            "keyColor": "{{blue}}"
        },
        {
            "type": "memory",
            "key": "│ ├󰛥",
            "format": "{used} / {total}",
            "keyColor": "{{blue}}"
        },
        {
            "type": "swap",
            "key": "└ └󰓡",
            "keyColor": "{{blue}}"
        },
        {
            "type": "custom",
            "format": "└────────────────────────────────────────────────────┘",
            "formatColor": "{{overlay0}}"
        },
        "break",
        {
            "type": "custom",
            "format": "┌──────────────────────Software──────────────────────┐",
            "formatColor": "{{overlay0}}"
        },
        {
            "type": "os",
            "key": "  󰘬 OS",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "kernel",
            "key": "│ ├󰀓",
            "format": "{release}",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "wm",
            "key": "│ ├󰒈",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "de",
            "key": "│ ├󰭹",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "terminal",
            "key": "│ ├󰒉",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "packages",
            "key": "│ ├󰏖",
            "combined": true,
            "keyColor": "{{mauve}}"
        },
        {
            "type": "wmtheme",
            "key": "│ ├󰉼",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "terminalfont",
            "key": "└ └󰀱",
            "format": "{/name}{-}{/}{name}{?size} {size}{?}",
            "keyColor": "{{mauve}}"
        },
        {
            "type": "custom",
            "format": "└────────────────────────────────────────────────────┘",
            "formatColor": "{{overlay0}}"
        },
        "break",
        {
            "type": "custom",
            "format": "┌──────────────────────Session───────────────────────┐",
            "formatColor": "{{overlay0}}"
        },
        {
            "type": "uptime",
            "key": "  󱫐 Uptime",
            "keyColor": "{{green}}"
        },
        {
            "type": "shell",
            "key": "│ ├󰘔",
            "keyColor": "{{green}}"
        },
        {
            "type": "theme",
            "key": "└ └󰸌",
            "keyColor": "{{green}}"
        },
        {
            "type": "custom",
            "format": "└────────────────────────────────────────────────────┘",
            "formatColor": "{{overlay0}}"
        },
        "break",
        "colors"
    ]
}
