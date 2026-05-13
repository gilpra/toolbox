#!/usr/bin/env bash

set -euo pipefail

if ! grep -q "^\[multilib\]$" /etc/pacman.conf; then
    echo
    echo "Enable multilib..."
    sudo cp /etc/pacman.conf /etc/pacman.conf.bak
    sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf
fi
sudo pacman -Syu --noconfirm

echo
echo "Installing Intel graphics packages..."
sudo pacman -S --noconfirm --needed \
    mesa \
    lib32-mesa \
    vulkan-intel \
    lib32-vulkan-intel \
    intel-media-driver

echo
echo "Installing additional gaming packages..."
sudo pacman -S --noconfirm --needed \
    gamemode \
    gamescope \
    zenity

echo
echo "Installing power-profiles-daemon..."
sudo pacman -S --noconfirm --needed \
    power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon

echo
echo "Configuring GameMode..."
mkdir -p ~/.config

tee ~/.config/gamemode.ini >/dev/null <<EOF
[general]
desiredprof=performance
renice=5
inhibit_screensaver=1
EOF

sudo gpasswd -a "$USER" gamemode

echo
echo "Enable ntsync..."
if sudo modprobe ntsync; then
    echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf
    echo 'KERNEL=="ntsync", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-ntsync.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
else
    echo "[WARN] ntsync is not available in the current kernel — skipping"
fi

echo
echo "Installing zram..."
sudo pacman -S --noconfirm --needed \
    zram-generator

echo
echo "Setup zram-generator..."

[ -f /etc/systemd/zram-generator.conf ] &&
    sudo cp /etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf.bak

sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service

echo
echo "Checking zram..."
swapon --summary

echo
echo "Checking power profile..."
powerprofilesctl get

echo
echo "Checking kernel..."
uname -r

echo
echo "Setup gaming for Intel Arch Linux complete!"
