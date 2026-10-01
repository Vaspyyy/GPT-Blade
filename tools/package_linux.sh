#!/usr/bin/env bash
# Build a real native Linux executable and portable release archives.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
godot_bin="${GODOT:-godot}"
version="${VERSION:-1.0.0}"
if [[ ! "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf 'VERSION must contain only letters, digits, dots, underscores, and hyphens.\n' >&2
    exit 1
fi
package_name="spin-ascend-${version}-linux-x86_64"
build_dir="$project_dir/build"
mkdir -p "$build_dir"
staging_root="$(mktemp -d "$build_dir/.package-${version}.XXXXXX")"
trap 'rm -rf -- "$staging_root"' EXIT
staging="$staging_root/$package_name"
mkdir -p "$staging"

if [[ "$project_dir" == /workspace/* ]]; then
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/tooling/config}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/tooling/cache}"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
fi

if [[ -n "${GODOT_DATA_HOME:-}" ]]; then
    export XDG_DATA_HOME="$GODOT_DATA_HOME"
elif [[ -f /workspace/tooling/godot-data/godot/export_templates/4.6.3.stable/linux_release.x86_64 ]]; then
    export XDG_DATA_HOME=/workspace/tooling/godot-data
fi
if [[ "$("$godot_bin" --headless --version)" != 4.6.3.stable* ]]; then
    printf 'Godot 4.6.3 is required. Set GODOT to its executable.\n' >&2
    exit 1
fi

"$godot_bin" --headless --path "$project_dir" --editor --import --quit
"$godot_bin" --headless --path "$project_dir" --export-release "Linux x86_64" "$staging/spin-ascend.x86_64"
chmod +x "$staging/spin-ascend.x86_64"
install -m 755 tools/play_linux.sh "$staging/play.sh"
cp docs/LINUX.md "$staging/README-LINUX.md"
cp assets/fonts/LICENSE.txt "$staging/FONT_LICENSE.txt"
cp docs/GODOT_LICENSE.txt docs/GODOT_COPYRIGHT.txt "$staging/"
cp docs/APACHE-2.0.txt "$staging/"
if [[ -f LICENSE ]]; then cp LICENSE "$staging/LICENSE"; fi
if [[ -f README.md ]]; then cp README.md "$staging/README.md"; fi
if [[ -f docs/PLAYTESTS.md ]]; then cp docs/PLAYTESTS.md "$staging/PLAYTESTS.md"; fi

file "$staging/spin-ascend.x86_64"
"$staging/spin-ascend.x86_64" --headless --version
(
    cd "$staging_root"
    tar -czf "$package_name.tar.gz" "$package_name"
    zip -q -r "$package_name.zip" "$package_name"
)
# Preserve the previous working package until the fresh export is complete.
rm -rf -- "$build_dir/$package_name"
mv "$staging" "$build_dir/$package_name"
mv "$staging_root/$package_name.tar.gz" "$staging_root/$package_name.zip" "$build_dir/"
(
    cd "$build_dir"
    sha256sum "$package_name.tar.gz" "$package_name.zip" > SHA256SUMS
)
printf 'Release archives: %s/build/%s.{tar.gz,zip}\n' "$project_dir" "$package_name"
