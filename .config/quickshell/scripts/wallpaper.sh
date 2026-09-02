#!/usr/bin/env bash

WALL_DIR="${WALLPAPERS_DIR:-$HOME/wallpapers}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_engine"
THUMB_DIR="$CACHE_DIR/thumbs"
mkdir -p "$CACHE_DIR" "$THUMB_DIR"

LOCK_FILE="$XDG_RUNTIME_DIR/wall_switcher.lock"

acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        exit 0
    fi
}

# Daemon check
ensure_daemon() {
    if ! awww query &> /dev/null; then
        awww-daemon --format xrgb &
        sleep 0.2
    fi
}

if [ "$1" == "--list" ]; then
    find "$WALL_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort | while read -r img; do
        hash=$(echo -n "$img" | md5sum | cut -d' ' -f1)
        thumb="$THUMB_DIR/$hash.jpg"
        echo "$img|$thumb"
        if [ ! -f "$thumb" ]; then
            if command -v ffmpeg &> /dev/null; then
                (ffmpeg -nostdin -loglevel error -y -i "$img" -vf "scale=200:200:force_original_aspect_ratio=increase,crop=200:200" "$thumb" < /dev/null >/dev/null 2>&1 &)
            elif command -v convert &> /dev/null; then
                (convert "$img" -resize 200x200^ -gravity center -extent 200x200 "$thumb" >/dev/null 2>&1 &)
            else
                (cp "$img" "$thumb" &)
            fi
        fi
    done
    exit 0
fi

acquire_lock

CURSOR_POS=$(hyprctl cursorpos 2>/dev/null | tr -d ' ' | grep -E "^[0-9]" || echo "0,0")
if [ -z "$CURSOR_POS" ]; then
    CURSOR_POS="0,0"
fi

if [ "$1" == "--restore" ]; then
    ensure_daemon
    if [ -f "$CACHE_DIR/current_wall" ]; then
        SELECTED_WALL=$(cat "$CACHE_DIR/current_wall")
    fi
    TRANSITION_ARGS=(--transition-type none)
elif [ "$1" == "--set" ] && [ -n "$2" ]; then
    SELECTED_WALL="$2"
    TRANSITION_ARGS=(--transition-type grow --transition-pos "$CURSOR_POS" --transition-duration 0.8 --transition-fps 60 --transition-bezier .43,1.19,1,.4)
else
    SELECTED_WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
    TRANSITION_ARGS=(--transition-type grow --transition-pos "$CURSOR_POS" --transition-duration 0.8 --transition-fps 60 --transition-bezier .43,1.19,1,.4)
fi

if [ -z "$SELECTED_WALL" ] || [ ! -f "$SELECTED_WALL" ]; then exit 1; fi

ensure_daemon

awww img "$SELECTED_WALL" "${TRANSITION_ARGS[@]}" &
matugen image "$SELECTED_WALL" -t scheme-smart --source-color-index 0 > /dev/null 2>&1 &
echo "$SELECTED_WALL" > "$CACHE_DIR/current_wall"



