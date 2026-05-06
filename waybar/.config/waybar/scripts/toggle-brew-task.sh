#!/usr/bin/env bash

BREW_TASK_BIN="$HOME/.config/brew-task/brew_task.py"

if python3 "$BREW_TASK_BIN" ping 2>/dev/null; then
    python3 "$BREW_TASK_BIN" toggle
else
    nohup python3 "$BREW_TASK_BIN" >/dev/null 2>&1 &
    disown
fi
