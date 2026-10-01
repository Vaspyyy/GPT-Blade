#!/usr/bin/env bash
# Read-only host diagnostics; optional smoke test uses the actual release.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
game="${1:-$project_dir/build/spin-ascend-1.0.0-linux-x86_64/spin-ascend.x86_64}"
printf 'Architecture: %s\n' "$(uname -m)"
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    printf 'OS: %s\n' "$PRETTY_NAME"
fi
printf 'Session type: %s\nWayland display: %s\nX11 display: %s\n' "${XDG_SESSION_TYPE:-unset}" "${WAYLAND_DISPLAY:-unset}" "${DISPLAY:-unset}"
printf 'Desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unset}"
getconf GNU_LIBC_VERSION
if [[ ! -x "$game" ]]; then
    printf 'No runnable build at %s\nRun tools/package_linux.sh first.\n' "$game" >&2
    exit 1
fi
file "$game"
ldd "$game"
"$game" --headless --version
if [[ "${2:-}" == --smoke ]]; then
    display_driver=x11
    if [[ -n "${WAYLAND_DISPLAY:-}" || "${XDG_SESSION_TYPE:-}" == wayland ]]; then display_driver=wayland; fi
    printf 'Running a real %s window for 120 frames.\n' "$display_driver"
    timeout 30 "$game" --display-driver "$display_driver" --rendering-method gl_compatibility --quit-after 120
fi
