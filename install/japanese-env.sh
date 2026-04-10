#!/usr/bin/env bash
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
FONT_FILE="$FONT_DIR/NotoSansJP-VariableFont_wght.ttf"

mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_FILE" ]; then
  echo
  echo "Download japanese font..."
  curl -fL -o "$FONT_FILE" \
    "https://github.com/gilang-arya/assets-repo/raw/main/assets/fonts/NotoSansJP-VariableFont_wght.ttf"
else
  echo "Font already exists, skipping download."
fi

echo
echo "Refresh font cache"
fc-cache -fv "$FONT_DIR"
