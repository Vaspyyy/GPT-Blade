#!/usr/bin/env bash
# Official Godot 4.6.3 Linux export templates; TLS + pinned SHA512 verification.
set -euo pipefail
data_home="${GODOT_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}"
cache_dir="${GODOT_DOWNLOAD_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/spin-ascend-downloads}"
template_dir="$data_home/godot/export_templates/4.6.3.stable"
archive_name=Godot_v4.6.3-stable_export_templates.tpz
archive_sha=da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
release_sha=e56a29c6cf4a794147f2d3bac8283e41095b8d9a96a4d132693a60df42de1c01ff1c5f9b24343cb464fd272349773b03c8fe83814a5d3467880ac0acc1282dbd
debug_sha=db00e3698e862be6c9b4534f12de7f31dd792362f7acab57751835426a4e5e13e5b16057d968c12797dd583943abe0022ed13ef0f43174b8d5d8f5a7519d5380
verify_templates() {
    [[ -f "$template_dir/linux_release.x86_64" && -f "$template_dir/linux_debug.x86_64" ]] || return 1
    printf '%s  %s\n%s  %s\n' "$release_sha" "$template_dir/linux_release.x86_64" "$debug_sha" "$template_dir/linux_debug.x86_64" | sha512sum --check --status
}
if verify_templates; then
    printf 'Verified Linux export templates: %s\n' "$template_dir"
    exit 0
fi
mkdir -p "$cache_dir" "$template_dir"
archive="$cache_dir/$archive_name"
if [[ ! -f "$archive" ]] || ! printf '%s  %s\n' "$archive_sha" "$archive" | sha512sum --check --status; then
    curl --fail --location --show-error --retry 2 --max-time 900 \
        "https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/$archive_name" -o "$archive"
fi
printf '%s  %s\n' "$archive_sha" "$archive" | sha512sum --check
unzip -j -o "$archive" templates/linux_release.x86_64 templates/linux_debug.x86_64 templates/version.txt -d "$template_dir"
verify_templates
printf 'Installed and verified Linux export templates: %s\n' "$template_dir"
