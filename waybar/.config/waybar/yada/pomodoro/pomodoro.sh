#!/bin/bash

STATE_FILE="/tmp/pomodoro_state"
WORK_TIME=1500  # 25 minutes
BREAK_TIME=300  # 5 minutes

# Icons
ICON_WORK=""
ICON_BREAK=""
ICON_STOP=""

# --- STATE INITIALIZATION ---
if [ ! -f "$STATE_FILE" ]; then
    echo "work stopped $WORK_TIME $(date +%s)" > "$STATE_FILE"
fi

read state status remaining last_epoch < "$STATE_FILE"
current_epoch=$(date +%s)

# --- ACTION HANDLERS ---
case "$1" in
    "toggle")
        # MIDDLE CLICK: Hard Reset to Work Start
        # Always sets to WORK, 25 mins, and STOPPED.
        status="stopped"
        state="work"
        remaining=$WORK_TIME
        
        echo "$state $status $remaining $current_epoch" > "$STATE_FILE"
        exit 0
        ;;
    "click")
        # LEFT CLICK
        if [ "$status" == "ringing" ]; then
            # Ringing -> Start Next Phase immediately
            if [ "$state" == "work" ]; then
                state="break"
                remaining=$BREAK_TIME
            else
                state="work"
                remaining=$WORK_TIME
            fi
            status="running"
        elif [ "$status" == "stopped" ]; then
            # Stopped -> Start Running
            status="running"
        fi
        # Note: If status is "running", we do nothing (No Pause)
        
        echo "$state $status $remaining $current_epoch" > "$STATE_FILE"
        exit 0
        ;;
esac

# --- TIMER COMPUTATION ---
if [ "$status" == "running" ]; then
    diff=$((current_epoch - last_epoch))
    remaining=$((remaining - diff))

    if [ "$remaining" -le 0 ]; then
        remaining=0
        status="ringing"

        # ALERTS: Sound and Notification
        # 'nohup' ensures sound plays even if the script process ends quickly
        nohup paplay $HOME/.config/brewland/pomodoro/sound/pomodoro.mp3 >/dev/null 2>&1 &
        
        if [ "$state" == "work" ]; then
            notify-send -u critical "POMODORO" "WORK DONE! Break time."
        else
            notify-send -u normal "POMODORO" "BREAK OVER! Get to work."
        fi
    fi
fi

echo "$state $status $remaining $current_epoch" > "$STATE_FILE"

# --- FORMATTING & UI OUTPUT ---
minutes=$((remaining / 60))
seconds=$((remaining % 60))
printf -v formatted "%02d:%02d" $minutes $seconds

# Icons & Classes
css_class="idle"
text_icon=""

if [ "$state" == "work" ]; then
    text_icon="$ICON_WORK"
else
    text_icon="$ICON_BREAK"
fi

if [ "$status" == "ringing" ]; then
    css_class="critical" 
    if [ "$state" == "work" ]; then
        tooltip="Work Done! Left-click to start break."
    else
        tooltip="Break Over! Left-click to work."
    fi
elif [ "$status" == "stopped" ]; then
    css_class="stopped"
    text_icon="$ICON_STOP" # Visual cue that it is stopped
    tooltip="Stopped. Left-click to start."
else
    # Running
    css_class="running"
    tooltip="Running: ${state^} phase."
fi

echo "{\"text\": \"$text_icon $formatted\", \"tooltip\": \"$tooltip\", \"class\": \"$css_class\"}"