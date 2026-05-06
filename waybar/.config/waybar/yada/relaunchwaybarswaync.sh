#!/bin/bash

# nuclear relaunch for bar and notifications

killall -9 waybar
swaync-client -R
swaync-client -rs
killall -9 swaync

waybar &
swaync &
