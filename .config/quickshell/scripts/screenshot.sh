#!/usr/bin/env bash
set -e

REQUIRED_CMDS=("grim" "slurp" "notify-send" "wl-copy")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done

temp_screenshot=$(mktemp -t screenshot_XXXXXX.png)
trap 'rm -f "$temp_screenshot"' EXIT

XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
save_dir="${save_dir:-$XDG_PICTURES_DIR/Screenshots}"
mkdir -p "$save_dir"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')

annotation_tool=""
if command -v satty &> /dev/null; then
    annotation_tool="satty"
fi

take_screenshot() {
    local mode=$1
    case "$mode" in
        "screen")
            grim "$temp_screenshot"
            ;;
        "output")
            if command -v jq &> /dev/null && command -v hyprctl &> /dev/null; then
                focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
                if [ -n "$focused_monitor" ]; then
                    grim -o "$focused_monitor" "$temp_screenshot"
                else
                    grim "$temp_screenshot"
                fi
            else
                grim "$temp_screenshot"
            fi
            ;;
        "area")
            geometry=$(slurp -b 00000080 -c 8aadf4 -w 2) || exit 0
            sleep 0.2
            grim -g "$geometry" "$temp_screenshot"
            ;;
        *)
            exit 1
            ;;
    esac
}

case "${1}" in
    "p") take_screenshot "screen" ;;
    "s"|"sf") take_screenshot "area" ;;
    "m") take_screenshot "output" ;;
    *) exit 1 ;;
esac

if [ -f "$temp_screenshot" ] && [ -s "$temp_screenshot" ]; then
    final_target="${save_dir}/${save_file}"
    if [[ -n "$annotation_tool" ]]; then
        if "$annotation_tool" --disable-notifications --filename "$temp_screenshot" --output-filename "$final_target"; then
            if [ -f "$final_target" ]; then
                wl-copy < "$final_target"
                notify-send -a "Screenshot" "Screenshot Saved & Copied" "$final_target" -i "$final_target"
            fi
        else
            cp "$temp_screenshot" "$final_target"
            wl-copy < "$final_target"
            notify-send -a "Screenshot" "Screenshot Saved & Copied" "$final_target" -i "$final_target"
        fi
    else
        cp "$temp_screenshot" "$final_target"
        wl-copy < "$final_target"
        notify-send -a "Screenshot" "Screenshot Saved & Copied" "$final_target" -i "$final_target"
    fi
fi
