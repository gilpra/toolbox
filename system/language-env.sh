#!/usr/bin/env bash
set -euo pipefail

LANG=("japanese" "korean")
FONT_DIR="$HOME/.local/share/fonts"

echo "Language:"
for i in ${!LANG[@]}; do
    echo "$((i + 1)). ${LANG[i]^}"
done

echo
read -p "Select Language (number) : " sel

# Check if input not number
if ! [[ $sel =~ ^[0-9]+$ ]]; then
    echo "Input not number"
    exit 1
fi

# Check if input out bound
sel=$((sel - 1))
if ((sel < 0 || sel >= "${#LANG[@]}")); then
    echo "Options out of reach"
    exit 1
fi

echo "${LANG[sel]}"
if [[ "${LANG[sel]}" == "japanese" ]]; then
    echo "You choose Japanese"
    FONT_FILE="NotoSansJP-VariableFont_wght.ttf"
    LOCALES="ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8"

elif [[ "${LANG[sel]}" == "korean" ]]; then
    FONT_FILE="NotoSansKR-VariableFont_wght.ttf"
    LOCALES="ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8"

fi

mkdir -p "$FONT_DIR"

FONT_LOCATE="$FONT_DIR/$FONT_FILE"

if [ ! -f "$FONT_LOCATE" ]; then
    echo
    echo "Download japanese font..."
    curl -fL -o "$FONT_LOCATE" "https://github.com/gilpra/assets-repo/raw/main/assets/fonts/$FONT_FILE"
else
    echo "Font already exists, skipping download."
fi

echo
echo "Refresh font cache"
fc-cache -fv "$FONT_DIR"

echo
echo "Setting locales..."
sudo sed -i "s/^# *${LOCALES}/" /etc/locale.gen

echo
echo "Generating locales..."
sudo locale-gen

echo
echo "Installation complete!"
