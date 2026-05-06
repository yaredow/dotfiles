#!/bin/bash

# mounts remote backup drive using rclone
# uses vfs caching for speed

MOUNTPOINT="/home/nkr/backup"
REMOTE="backup:"
PIDFILE="/tmp/rclone-work.pid"

if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "already mounted (PID $(cat $PIDFILE))"
    exit 1
fi

mkdir -p "$MOUNTPOINT"
echo "mounting $REMOTE..."

rclone mount "$REMOTE" "$MOUNTPOINT" \
    --dir-cache-time 8760h \
    --rc &

PID=$!
echo $PID > "$PIDFILE"
echo "mounted (PID $PID)"

# background refresh to speed things up
sleep 3
rclone rc vfs/refresh recursive=true &

echo "done. cache is warming up."