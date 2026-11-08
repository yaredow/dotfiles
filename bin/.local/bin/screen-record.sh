#!/usr/bin/env bash
#
# screen-record.sh - Toggle region or fullscreen recording using wf-recorder & slurp
#

set -euo pipefail

RECORDINGS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
PID_FILE="/tmp/screen-record.pid"
INFO_FILE="/tmp/screen-record.info"

# Ensure output directory exists
mkdir -p "$RECORDINGS_DIR"

stop_recording() {
    # Notify Noctalia service if active
    noctalia msg plugin noctalia/screen_recorder:service all stop 2>/dev/null || true
    local pid=""
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        pid=$(cat "$PID_FILE")
    elif pgrep -x wf-recorder >/dev/null; then
        pid=$(pgrep -x wf-recorder | head -n1)
    fi

    if [[ -n "$pid" ]]; then
        # Send SIGINT so wf-recorder cleanly finalizes MP4 headers
        kill -INT "$pid" 2>/dev/null || true

        local count=0
        while kill -0 "$pid" 2>/dev/null && [[ $count -lt 50 ]]; do
            sleep 0.1
            count=$((count + 1))
        done

        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi

        rm -f "$PID_FILE"

        local saved_file=""
        if [[ -f "$INFO_FILE" ]]; then
            saved_file=$(cat "$INFO_FILE")
            rm -f "$INFO_FILE"
        fi

        if [[ -n "$saved_file" && -f "$saved_file" ]]; then
            # Copy path to clipboard if wl-copy is available
            if command -v wl-copy >/dev/null 2>&1; then
                printf "%s" "$saved_file" | wl-copy || true
            fi
            notify-send -i media-record -a "Screen Recorder" "Recording Saved" "$(basename "$saved_file") (copied path)"
        else
            notify-send -i media-record -a "Screen Recorder" "Recording Stopped" "Screen recording finished."
        fi
        exit 0
    else
        rm -f "$PID_FILE" "$INFO_FILE"
        exit 0
    fi
}

start_recording() {
    local mode="${1:-region}"
    local with_audio="${2:-no}"
    local geom=""

    if [[ "$mode" == "region" ]]; then
        # Extract theme colors if available, otherwise fallback to sensible defaults
        local base_color="#1a1b26"
        local accent_color="#7aa2f7"
        local theme_colors="$HOME/.config/theme/current/colors.json"

        if [[ -f "$theme_colors" ]] && command -v jq >/dev/null 2>&1; then
            base_color=$(jq -r '.base // "#1a1b26"' "$theme_colors" 2>/dev/null || echo "#1a1b26")
            accent_color=$(jq -r '.blue // .accent // "#7aa2f7"' "$theme_colors" 2>/dev/null || echo "#7aa2f7")
        fi

        # Remove any leading # if needed, ensure valid hex
        base_color="#${base_color#'#'}"
        accent_color="#${accent_color#'#'}"

        # Prompt user to select region
        geom=$(slurp -d -b "${base_color}99" -c "${accent_color}" -s "${accent_color}33" -w 2 || true)
        if [[ -z "$geom" ]]; then
            # Cancelled by user (e.g. Esc)
            exit 0
        fi
    fi

    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local output_file="${RECORDINGS_DIR}/recording_${timestamp}.mp4"

    local -a cmd=("wf-recorder" "-c" "libx264" "-x" "yuv420p" "-p" "preset=veryfast" "-p" "crf=22")

    if [[ -n "$geom" ]]; then
        cmd+=("-g" "$geom")
    fi

    if [[ "$with_audio" == "yes" || "$with_audio" == "audio" ]]; then
        cmd+=("-a")
    fi

    cmd+=("-f" "$output_file")

    echo "$output_file" > "$INFO_FILE"

    # Start recording process detached
    "${cmd[@]}" >/dev/null 2>&1 &
    local rec_pid=$!
    echo "$rec_pid" > "$PID_FILE"

    sleep 0.3
    if kill -0 "$rec_pid" 2>/dev/null; then
        local label="Region"
        if [[ "$mode" == "fullscreen" ]]; then
            label="Fullscreen"
        fi
        if [[ "$with_audio" == "yes" || "$with_audio" == "audio" ]]; then
            label="${label} (with audio)"
        fi
        notify-send -i media-record -a "Screen Recorder" "Recording Started" "${label} recording started. Toggle hotkey to finish."
    else
        rm -f "$PID_FILE" "$INFO_FILE"
        notify-send -u critical -i dialog-error -a "Screen Recorder" "Recording Failed" "Could not start wf-recorder."
        exit 1
    fi
}

ACTION="region"
WITH_AUDIO="no"

for arg in "$@"; do
    case "$arg" in
        stop)
            stop_recording
            ;;
        status)
            if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
                echo "recording"
                exit 0
            elif pgrep -x wf-recorder >/dev/null; then
                echo "recording"
                exit 0
            else
                echo "idle"
                exit 1
            fi
            ;;
        region|toggle)
            ACTION="region"
            ;;
        fullscreen|screen)
            ACTION="fullscreen"
            ;;
        --audio|-a)
            WITH_AUDIO="yes"
            ;;
        *)
            ;;
    esac
done

# If already recording, stop it
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    stop_recording
elif pgrep -x wf-recorder >/dev/null; then
    stop_recording
fi

# Otherwise start recording
start_recording "$ACTION" "$WITH_AUDIO"
