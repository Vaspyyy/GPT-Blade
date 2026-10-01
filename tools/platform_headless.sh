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
socket=""
for candidate in "$XDG_RUNTIME_DIR"/sway-ipc.*.sock; do
    if [[ -S "$candidate" ]] && swaymsg -s "$candidate" -t get_version >/dev/null 2>&1; then
        socket="$candidate"
        break
    fi
done
resolve_display() {
    # Sway chooses the next free socket; a restored workspace can retain stale ones.
    local actual_display=""
    if [[ -r "$tooling_dir/logs/sway.log" ]]; then
        actual_display="$(sed -n "s/.*Running compositor on wayland display '\(wayland-[0-9]*\)'.*/\1/p" "$tooling_dir/logs/sway.log" | tail -1)"
    fi
    if [[ -n "$actual_display" && -S "$XDG_RUNTIME_DIR/$actual_display" ]]; then
        export WAYLAND_DISPLAY="$actual_display"
    fi
}
if [[ -n "$socket" ]]; then resolve_display; fi
ensure_pointer() {
    local pointer_pid=""
    if [[ -f "$tooling_dir/pointer.pid" ]]; then
        read -r pointer_pid < "$tooling_dir/pointer.pid" || true
    fi
    if [[ "$pointer_pid" =~ ^[0-9]+$ ]] && kill -0 "$pointer_pid" 2>/dev/null &&
       [[ "$(readlink "/proc/$pointer_pid/exe" 2>/dev/null)" == "$tooling_dir/platform-pointer" && -p "$XDG_RUNTIME_DIR/pointer.fifo" ]]; then
        return
    fi
    # This is our development-only FIFO, not a player save or compositor socket.
    rm -f -- "$XDG_RUNTIME_DIR/pointer.fifo"
    if [[ -x "$tooling_dir/platform-pointer" ]]; then
        nohup "$tooling_dir/platform-pointer" "$XDG_RUNTIME_DIR/pointer.fifo" 1440 900 > "$tooling_dir/logs/pointer.log" 2>&1 &
        echo $! > "$tooling_dir/pointer.pid"
        for _ in {1..100}; do
            [[ -p "$XDG_RUNTIME_DIR/pointer.fifo" ]] && return
            sleep 0.05
        done
        printf 'Virtual input did not start; inspect %s/logs/pointer.log.\n' "$tooling_dir" >&2
        exit 1
    fi
}
key_code() {
    case "$1" in
        space|Space) echo 57 ;; Return|Enter) echo 28 ;; Escape|Esc) echo 1 ;; F11) echo 87 ;;
        Left) echo 105 ;; Right) echo 106 ;; Up) echo 103 ;; Down) echo 108 ;;
        b|B) echo 48 ;; c|C) echo 46 ;; l|L) echo 38 ;; p|P) echo 25 ;;
        1) echo 2 ;; 2) echo 3 ;; 3) echo 4 ;; 4) echo 5 ;;
        *) printf 'Unknown test key: %s\n' "$1" >&2; return 1 ;;
    esac
}

case "${1:-}" in
    start)
        if [[ -n "$socket" ]]; then
            ensure_pointer
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
        compositor_pid="$!"
        ready=false
        for _ in {1..100}; do
            for candidate in "$XDG_RUNTIME_DIR"/sway-ipc.*.sock; do
                if [[ -S "$candidate" ]] && swaymsg -s "$candidate" -t get_version >/dev/null 2>&1; then
                    socket="$candidate"
                    resolve_display
                    if [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then ready=true; break; fi
                fi
            done
            if [[ "$ready" == true ]]; then break; fi
            if ! kill -0 "$compositor_pid" 2>/dev/null; then break; fi
            sleep 0.05
        done
        if [[ "$ready" != true ]]; then
            printf 'Compositor did not create a display; inspect %s/logs/sway.log.\n' "$tooling_dir" >&2
            exit 1
        fi
        ensure_pointer
        printf 'Started compositor PID %s; log: %s/logs/sway.log\n' "$compositor_pid" "$tooling_dir"
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
        ensure_pointer
        if [[ -p "$XDG_RUNTIME_DIR/pointer.fifo" ]]; then
            printf 'click %s %s\n' "$2" "$3" > "$XDG_RUNTIME_DIR/pointer.fifo"
            # FIFO writes enqueue input; allow press/release and one frame to finish.
            sleep 0.20
        else
            printf 'Persistent virtual pointer needed: see docs/PLATFORM-TESTING.md.\n' >&2
            exit 1
        fi
        ;;
    key)
        ensure_pointer
        printf 'key %s\n' "$(key_code "${2:?keysym required}")" > "$XDG_RUNTIME_DIR/pointer.fifo"
        sleep 0.20
        ;;
    press)
        ensure_pointer
        printf 'press %s\n' "$(key_code "${2:?keysym required}")" > "$XDG_RUNTIME_DIR/pointer.fifo"
        sleep 0.12
        ;;
    release)
        ensure_pointer
        printf 'release %s\n' "$(key_code "${2:?keysym required}")" > "$XDG_RUNTIME_DIR/pointer.fifo"
        sleep 0.12
        ;;
    hold)
        ensure_pointer
        printf 'hold %s %s\n' "$(key_code "${2:?keysym required}")" "${3:?milliseconds required}" > "$XDG_RUNTIME_DIR/pointer.fifo"
        sleep "$(awk -v ms="$3" 'BEGIN {printf "%.3f", (ms+180)/1000}')"
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
        if [[ -p "$XDG_RUNTIME_DIR/pointer.fifo" ]]; then printf 'quit\n' > "$XDG_RUNTIME_DIR/pointer.fifo"; fi
        if [[ -n "$socket" ]]; then swaymsg -s "$socket" exit; fi
        ;;
    *)
        printf 'Usage: %s start|env|run COMMAND...|capture PNG|click X Y|key KEY|hold KEY MS|resize WIDTHxHEIGHT|stop\n' "$0" >&2
        exit 1
        ;;
esac
