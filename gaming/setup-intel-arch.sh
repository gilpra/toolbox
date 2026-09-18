#!/usr/bin/env bash

set -Eeuo pipefail

# Enable multilib
if ! grep -q '^\[multilib\]$' /etc/pacman.conf; then
    echo
    echo 'Enabling multilib...'
    sudo cp -a /etc/pacman.conf /etc/pacman.conf.bak
    # Uncomment [multilib] block.
    sudo sed -i \
        '/^[[:space:]]*#\[multilib\][[:space:]]*$/,/^[[:space:]]*#Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/mirrorlist[[:space:]]*$/ s/^[[:space:]]*#//' \
        /etc/pacman.conf
fi

# Update system
sudo pacman -Syu --noconfirm

# Instal package
echo
echo "Installing Gaming and Intel graphics packages..."
sudo pacman -S --needed \
    mesa \
    vulkan-intel \
    intel-media-driver \
    gamemode \
    gamescope \
    ntsync-autoload

# Gamemode
echo
echo 'Configuring Gamemode...'
sudo usermod -aG gamemode "$USER"
mkdir -p "$HOME/.config"
cat >"$HOME/.config/gamemode.ini" <<'GAMEMODE'
[general]
desiredgov=performance
renice=5
inhibit_screensaver=1
GAMEMODE

echo
echo 'Gaming setup complete.'

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx 'gamemode'; then
    echo
    echo 'IMPORTANT:'
    echo 'Log out and log back in once so the gamemode group becomes active.'
    echo 'Then verify GameMode with:'
    echo
    echo 'gamemoded -t'
fi
