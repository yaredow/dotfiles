#!/bin/bash

IS_FLOATING=$(hyprctl activewindow -j | jq -r ".floating")

if [ "$IS_FLOATING" == "true" ]; then
    hyprctl dispatch togglefloating
else
    hyprctl dispatch togglefloating
    hyprctl dispatch resizeactive exact 60% 60%
    hyprctl dispatch centerwindow
fi