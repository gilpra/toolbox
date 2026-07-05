#!/usr/bin/env bash

set -euo pipefail

AUR_HELPER=("yay" "paru")

for i in "${!AUR_HELPER[@]}"; do
  echo "$((i + 1)). ${AUR_HELPER[$i]}"
done

read -p "Choose your AUR Helper (number): " SELECTED_AUR
echo

if ! [[ "$SELECTED_AUR" =~ ^[0-9]+$ ]]; then
  echo "Please enter a number"
  exit 1
fi

SELECTED="$((SELECTED_AUR - 1))"

if ((SELECTED < 0 || SELECTED >= "${#AUR_HELPER[@]}")); then
  echo "Invalid input"
  exit 1
fi

AUR="${AUR_HELPER[SELECTED]}"

if command -v "$AUR" &>/dev/null; then
  echo "$AUR already installed, skip the process"
  exit 0
fi

echo "Installed: ${AUR_HELPER[SELECTED]}"

sudo pacman -S --needed git base-devel

TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

echo
echo "Cloning AUR Helper from Repository..."

case "$AUR" in
yay)
  git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR"
  ;;
paru)
  git clone https://aur.archlinux.org/paru.git "$TEMP_DIR"
  ;;
esac

cd "$TEMP_DIR"

echo
echo "Building and installing $AUR..."
makepkg -si

echo
echo "$AUR installation complete!"
