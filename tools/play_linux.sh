#!/usr/bin/env bash
set -euo pipefail
game_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(uname -m)" != x86_64 ]]; then
    printf 'This build needs an x86_64 Linux computer.\n' >&2
    exit 1
fi
display_driver=x11
if [[ -n "${WAYLAND_DISPLAY:-}" || "${XDG_SESSION_TYPE:-}" == wayland ]]; then
    display_driver=wayland
fi
case "${1:-}" in
    --x11) display_driver=x11; shift ;;
    --wayland) display_driver=wayland; shift ;;
esac
exec "$game_dir/spin-ascend.x86_64" --display-driver "$display_driver" --rendering-method gl_compatibility --max-fps 120 "$@"
