#!/usr/bin/env bash
# Debian 13 cloud test tools installed into a local sysroot without root.
# apt validates Debian signatures and package checksums before extraction.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tooling_dir="${PLATFORM_TOOLING_DIR:-/workspace/tooling}"
apt_dir="$tooling_dir/apt"
sysroot="$tooling_dir/sysroot"
source_list="${PLATFORM_APT_SOURCES:-/etc/apt/sources.list.d/caas-snapshot.list}"
if [[ ! -r "$source_list" ]]; then
    printf 'Set PLATFORM_APT_SOURCES to a Debian 13 source list using a signed-by archive keyring.\n' >&2
    exit 1
fi
mkdir -p "$apt_dir/lists/partial" "$apt_dir/archives/partial" "$sysroot"
cat > "$apt_dir/apt.conf" <<EOF
Dir::Etc::parts "-";
Dir::Etc::main "-";
Dir::Etc::sourcelist "$source_list";
Dir::Etc::sourceparts "-";
Dir::State::lists "$apt_dir/lists";
Dir::State::status "/var/lib/dpkg/status";
Dir::Cache::archives "$apt_dir/archives";
Dir::Cache::pkgcache "$apt_dir/pkgcache.bin";
Dir::Cache::srcpkgcache "$apt_dir/srcpkgcache.bin";
Dir::Log "$apt_dir";
Debug::NoLocking "true";
APT::Sandbox::User "$(id -un)";
EOF
APT_CONFIG="$apt_dir/apt.conf" /usr/bin/apt-get update
APT_CONFIG="$apt_dir/apt.conf" /usr/bin/apt-get --download-only -y --no-install-recommends install \
    sway grim wtype xvfb xdotool wlrctl libwayland-dev libwayland-bin
for package in "$apt_dir/archives/"*.deb; do dpkg-deb -x "$package" "$sysroot"; done

protocol_url=https://raw.githubusercontent.com/swaywm/wlr-protocols/b010a03648b88d143236de193bddbfea0c08bc84/unstable/wlr-virtual-pointer-unstable-v1.xml
curl --fail --location --show-error --max-time 60 "$protocol_url" -o "$tooling_dir/wlr-virtual-pointer-unstable-v1.xml"
"$sysroot/usr/bin/wayland-scanner" client-header "$tooling_dir/wlr-virtual-pointer-unstable-v1.xml" "$tooling_dir/wlr-virtual-pointer.h"
"$sysroot/usr/bin/wayland-scanner" private-code "$tooling_dir/wlr-virtual-pointer-unstable-v1.xml" "$tooling_dir/wlr-virtual-pointer.c"
gcc -Wall -Wextra -I"$tooling_dir" -I"$sysroot/usr/include" \
    "$project_dir/tools/platform_pointer.c" "$tooling_dir/wlr-virtual-pointer.c" \
    -l:libwayland-client.so.0 -o "$tooling_dir/platform-pointer"
printf 'Native Wayland test tools ready in %s\n' "$tooling_dir"
