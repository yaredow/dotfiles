{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "builtin",
        "source": "arch",
        "padding": {
            "right": 2
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
        "key": {
            "width": 14,
            "type": "string"
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
        "os",
        "host",
        {
            "type": "kernel",
            "format": "{release}"
        },
        "uptime",
        {
            "type": "packages",
            "combined": true
        },
        "shell",
        {
            "type": "display",
            "compactType": "original",
            "key": "Resolution"
        },
        "de",
        "wm",
        "wmtheme",
        "theme",
        "icons",
        "terminal",
        {
            "type": "terminalfont",
            "format": "{/name}{-}{/}{name}{?size} {size}{?}"
        },
        "cpu",
        {
            "type": "gpu",
            "key": "GPU",
            "format": "{name}"
        },
        {
            "type": "memory",
            "format": "{used} / {total}"
        },
        "break",
        "colors"
    ]
}
