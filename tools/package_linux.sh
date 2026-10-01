#!/usr/bin/env bash
# Build a real native Linux executable and portable release archives.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
godot_bin="${GODOT:-godot}"
version="${VERSION:-1.0.0}"
package_name="spin-ascend-${version}-linux-x86_64"
staging="$project_dir/build/$package_name"
mkdir -p "$staging"

if [[ -n "${GODOT_DATA_HOME:-}" ]]; then
    export XDG_DATA_HOME="$GODOT_DATA_HOME"
elif [[ -f /workspace/tooling/godot-data/godot/export_templates/4.6.3.stable/linux_release.x86_64 ]]; then
    export XDG_DATA_HOME=/workspace/tooling/godot-data
fi
if [[ "$($godot_bin --headless --version)" != 4.6.3.stable* ]]; then
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
if [[ -f LICENSE ]]; then cp LICENSE "$staging/LICENSE"; fi

file "$staging/spin-ascend.x86_64"
"$staging/spin-ascend.x86_64" --headless --version
(
    cd "$project_dir/build"
    tar -czf "$package_name.tar.gz" "$package_name"
    # Remove only the generated archive, so zip cannot retain obsolete entries.
    rm -f "$package_name.zip"
    zip -q -r "$package_name.zip" "$package_name"
    sha256sum "$package_name.tar.gz" "$package_name.zip" > SHA256SUMS
)
printf 'Release archives: %s/build/%s.{tar.gz,zip}\n' "$project_dir" "$package_name"
