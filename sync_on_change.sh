#!/bin/bash

# This file will watch a folder and sync the changes to dropbox,
# This can be helpful if you are running a nextcloud instance, but you are also a class one dumbass
WATCH_DIR="/path/to/nextcloud/vital"
REMOTE_DIR="dropbox:/nextcloud"

inotifywait -m -r -e modify,create,delete,move "$WATCH_DIR" --format '%w%f' |
while read FILE; do
    echo "Change detected in $FILE. Syncing..."
    rclone sync "$WATCH_DIR" "$REMOTE_DIR"
done
