#!/usr/bin/env bash
set -Eeuo pipefail

LANGUAGES=("japanese" "korean")
FONT_DIR="$HOME/.local/share/fonts"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '\n==> %s\n' "$*"
}

command -v sudo >/dev/null 2>&1 || die 'sudo is required.'
command -v xbps-install >/dev/null 2>&1 || die 'xbps-install not found.'
command -v fc-cache >/dev/null 2>&1 || {
    info 'Installing Fontconfig'
    sudo xbps-install -y fontconfig
}

echo 'Language:'
for i in "${!LANGUAGES[@]}"; do
    printf '%d. %s\n' "$((i + 1))" "${LANGUAGES[i]^}"
done

echo
read -r -p 'Select Language (number): ' sel

[[ "$sel" =~ ^[0-9]+$ ]] || {
    echo 'Input not number'
    exit 1
}

sel=$((sel - 1))

((sel >= 0 && sel < ${#LANGUAGES[@]})) || {
    echo 'Options out of range'
    exit 1
}

LANG_NAME="${LANGUAGES[sel]}"

case "$LANG_NAME" in
japanese)
    FONT_FILE="NotoSansJP-VariableFont_wght.ttf"
    LOCALE_NAME="ja_JP.UTF-8"
    LOCALE_LINE="ja_JP.UTF-8 UTF-8"
    ;;
korean)
    FONT_FILE="NotoSansKR-VariableFont_wght.ttf"
    LOCALE_NAME="ko_KR.UTF-8"
    LOCALE_LINE="ko_KR.UTF-8 UTF-8"
    ;;
*)
    die "Unsupported language: $LANG_NAME"
    ;;
esac

echo "$LANG_NAME"

mkdir -p "$FONT_DIR"

FONT_LOCATION="$FONT_DIR/$FONT_FILE"

if [[ ! -f "$FONT_LOCATION" ]]; then
    info "Downloading ${FONT_FILE}"

    curl -fL \
        -o "$FONT_LOCATION" \
        "https://github.com/gilpra/assets-repo/raw/main/fonts/$FONT_FILE"
else
    echo 'Font already exists, skipping download.'
fi

info 'Refreshing font cache'
fc-cache -f "$FONT_DIR"

info "Enabling ${LOCALE_NAME}"

if grep -qE "^[[:space:]]*#?[[:space:]]*${LOCALE_NAME//./\\.}[[:space:]]+UTF-8[[:space:]]*$" \
    /etc/default/libc-locales; then

    sudo sed -i -E \
        "s|^[[:space:]]*#?[[:space:]]*(${LOCALE_NAME//./\\.}[[:space:]]+UTF-8)[[:space:]]*$|\1|" \
        /etc/default/libc-locales
else
    printf '%s\n' "$LOCALE_LINE" |
        sudo tee -a /etc/default/libc-locales >/dev/null
fi

info 'Generating locale data'
sudo xbps-reconfigure -f glibc-locales

echo
echo 'Installation complete!'
echo
echo 'Enabled locale:'
echo "  $LOCALE_NAME"
echo
echo 'Check with:'
echo '  locale -a'
