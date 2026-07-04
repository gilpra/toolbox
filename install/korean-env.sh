#!/usr/bin/env bash
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
FONT_FILE="$FONT_DIR/NotoSansKR-VariableFont_wght.ttf"

mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_FILE" ]; then
  echo
  echo "Download korean font..."
  curl -fL -o "$FONT_FILE" \
    "https://github.com/gilang-arya/assets-repo/raw/main/assets/fonts/NotoSansKR-VariableFont_wght.ttf"
else
  echo "Font already exists, skipping download."
fi

echo
echo "Refresh font cache"
fc-cache -fv "$FONT_DIR"

echo
echo "Setting locales..."
sudo sed -i 's/^# *ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen

echo
echo "Generating locales..."
sudo locale-gen

echo
echo "Installation complete!"
