#!/bin/bash

# toggle power profiles
# cycles between power-saver, balanced, and performance

CURRENT=$(powerprofilesctl get)

if [ "$CURRENT" == "power-saver" ]; then
    NEXT="balanced"
    ICON="⚖️"
    TEXT="Balanced Mode"
elif [ "$CURRENT" == "balanced" ]; then
    NEXT="performance"
    ICON="󱐋"
    TEXT="Performance"
else
    NEXT="power-saver"
    ICON=""
    TEXT="Power Saver"
fi

powerprofilesctl set $NEXT
notify-send -a "Power" "Power Profile" "switched to $ICON $TEXT"