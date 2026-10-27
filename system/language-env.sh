#!/usr/bin/env bash
set -Eeuo pipefail

LANGUAGES=(japanese korean)
FONT_DIR="$HOME/.local/share/fonts"

printf 'Language:\n'
for i in "${!LANGUAGES[@]}"; do
    printf '%d. %s\n' "$((i + 1))" "${LANGUAGES[$i]^}"
done

read -r -p 'Select language (number): ' selection
[[ "$selection" =~ ^[0-9]+$ ]] || { echo 'Input must be a number.' >&2; exit 1; }
index=$((selection - 1))
(( index >= 0 && index < ${#LANGUAGES[@]} )) || { echo 'Selection out of range.' >&2; exit 1; }

case "${LANGUAGES[$index]}" in
    japanese)
        font_file='NotoSansJP-VariableFont_wght.ttf'
        locale='ja_JP.UTF-8'
        langpack='glibc-langpack-ja'
        ;;
    korean)
        font_file='NotoSansKR-VariableFont_wght.ttf'
        locale='ko_KR.UTF-8'
        langpack='glibc-langpack-ko'
        ;;
esac

mkdir -p "$FONT_DIR"
font_path="$FONT_DIR/$font_file"
if [[ ! -f "$font_path" ]]; then
    echo "Downloading $font_file..."
    curl -fL --retry 3 \
        "https://github.com/gilpra/assets-repo/raw/main/fonts/$font_file" \
        -o "$font_path"
else
    echo 'Font already exists; skipping download.'
fi

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR"
else
    echo 'WARNING: fc-cache not found; install fontconfig to refresh font cache.' >&2
fi

# Fedora ships locale data separately in glibc-langpack-* packages.
# Install the selected locale data before asking systemd-localed to use it.
echo "Installing locale data package: $langpack ..."
sudo dnf install -y "$langpack"

# Confirm the selected locale is now available before changing system settings.
if ! localectl list-locales | grep -Eiq "^${locale//./\.}$|^${locale%.*}\.(utf8|UTF-8)$"; then
    echo "ERROR: locale $locale is still not listed after installing $langpack." >&2
    echo 'Check the DNF output and the installed glibc-langpack package.' >&2
    exit 1
fi

# Fedora uses localectl; unlike Arch, it does not use /etc/locale.gen + locale-gen.
echo "Setting system locale to $locale ..."
sudo localectl set-locale "LANG=$locale"

echo 'Done. Log out and back in for the locale change to apply to your session.'
