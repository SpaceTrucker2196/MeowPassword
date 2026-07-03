#!/usr/bin/env bash
# make_icon.sh — build AppIcon.icns from a single 1024x1024 source PNG.
#
# Usage:
#   ./make_icon.sh <source.png> [<out.icns>]
#
# Produces AppIcon.icns (default) containing the ten sizes macOS wants.

set -euo pipefail

SRC="${1:-/tmp/icon_sq.png}"
OUT="${2:-AppIcon.icns}"

if [[ ! -f "$SRC" ]]; then
    echo "ERROR: source PNG not found: $SRC" >&2
    exit 1
fi

STAGE=$(mktemp -d)/AppIcon.iconset
mkdir -p "$STAGE"
trap 'rm -rf "$(dirname "$STAGE")"' EXIT

# name           px
declare -a SIZES=(
    "icon_16x16.png:16"
    "icon_16x16@2x.png:32"
    "icon_32x32.png:32"
    "icon_32x32@2x.png:64"
    "icon_128x128.png:128"
    "icon_128x128@2x.png:256"
    "icon_256x256.png:256"
    "icon_256x256@2x.png:512"
    "icon_512x512.png:512"
    "icon_512x512@2x.png:1024"
)

for entry in "${SIZES[@]}"; do
    name="${entry%%:*}"
    px="${entry##*:}"
    sips -Z "$px" "$SRC" --out "$STAGE/$name" >/dev/null
done

iconutil -c icns "$STAGE" -o "$OUT"
echo "wrote $OUT ($(du -h "$OUT" | cut -f1))"
