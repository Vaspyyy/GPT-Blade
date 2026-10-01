#!/usr/bin/env bash
# Development-only native Wayland harness. The game does not depend on Sway.
set -euo pipefail
tooling_dir="${PLATFORM_TOOLING_DIR:-/workspace/tooling}"
tool_prefix="${PLATFORM_TOOL_PREFIX:-$tooling_dir/sysroot/usr}"
export PATH="$tool_prefix/bin:$PATH"
export LD_LIBRARY_PATH="$tool_prefix/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_RUNTIME_DIR="$tooling_dir/runtime"
export XDG_CACHE_HOME="$tooling_dir/cache"
export XDG_DATA_HOME="${PLATFORM_DATA_DIR:-$tooling_dir/player-data}"
export WAYLAND_DISPLAY=wayland-1
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$tooling_dir/logs"
chmod 700 "$XDG_RUNTIME_DIR"
socket="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit)"

case "${1:-}" in
    start)
        if [[ -n "$socket" ]]; then
            printf 'Compositor already running: %s\n' "$socket"
            exit 0
        fi
        cat > "$tooling_dir/headless-sway.conf" <<'EOF'
xwayland disable
output HEADLESS-1 mode 1440x900
seat seat0 fallback true
default_border none
focus_follows_mouse no
for_window [app_id=".*"] floating enable
for_window [app_id=".*"] fullscreen enable
EOF
        WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 nohup sway --config "$tooling_dir/headless-sway.conf" --debug > "$tooling_dir/logs/sway.log" 2>&1 &
        echo $! > "$tooling_dir/sway.pid"
        printf 'Started compositor PID %s; log: %s/logs/sway.log\n' "$!" "$tooling_dir"
        ;;
    env)
        printf 'export XDG_RUNTIME_DIR=%q WAYLAND_DISPLAY=%q XDG_CACHE_HOME=%q XDG_DATA_HOME=%q\n' "$XDG_RUNTIME_DIR" "$WAYLAND_DISPLAY" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
        ;;
    run)
        shift
        exec "$@"
        ;;
    capture)
        grim "${2:-$tooling_dir/logs/wayland-capture.png}"
        ;;
    click)
        : "${2:?screen X coordinate required}" "${3:?screen Y coordinate required}" "${socket:?Compositor not running}"
        if [[ -p "$XDG_RUNTIME_DIR/pointer.fifo" ]]; then
            printf 'click %s %s\n' "$2" "$3" > "$XDG_RUNTIME_DIR/pointer.fifo"
        else
            printf 'Persistent virtual pointer needed: see docs/PLATFORM-TESTING.md.\n' >&2
            exit 1
        fi
        ;;
    key)
        # Allow Godot to observe the newly-created virtual keyboard first.
        wtype -s 120 -k "${2:?keysym required, e.g. space, Return, Escape}" -s 120
        ;;
    press)
        wtype -s 120 -P "${2:?keysym required}" -s 120
        ;;
    release)
        wtype -s 120 -p "${2:?keysym required}" -s 120
        ;;
    hold)
        wtype -s 120 -P "${2:?keysym required}" -s "${3:?milliseconds required}" -p "$2" -s 120
        ;;
    resize)
        : "${socket:?Compositor not running}"
        swaymsg -s "$socket" "output HEADLESS-1 mode ${2:?WIDTHxHEIGHT required}"
        if [[ -p "$XDG_RUNTIME_DIR/pointer.fifo" ]]; then
            dimensions="$2"
            printf 'size %s %s\n' "${dimensions%x*}" "${dimensions#*x}" > "$XDG_RUNTIME_DIR/pointer.fifo"
        fi
        ;;
    stop)
        if [[ -n "$socket" ]]; then swaymsg -s "$socket" exit; fi
        ;;
    *)
        printf 'Usage: %s start|env|run COMMAND...|capture PNG|click X Y|key KEY|hold KEY MS|resize WIDTHxHEIGHT|stop\n' "$0" >&2
        exit 1
        ;;
esac
