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
echo "Installing intel package..."
sudo pacman -S --noconfirm --needed mesa vulkan-intel intel-media-driver

echo
echo "Optimization GRUB..."
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog intel_pstate=active i915.enable_guc=3 i915.enable_fbc=1 transparent_hugepage=madvise split_lock_detect=off zswap.enabled=0"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "Enable ntsync..."
sudo modprobe ntsync
echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf
echo 'KERNEL=="ntsync", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-ntsync.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

echo
echo "Installing additional gaming package..."
sudo pacman -S --noconfirm --needed gamemode gamescope zenity
tee ~/.config/gamemode.ini >/dev/null <<EOF
[general]
renice=10
inhibit_screensaver=1

[cpu]
park_cores=no
pin_cores=yes

[custom]
start=powerprofilesctl set performance
end=powerprofilesctl set balanced
EOF

echo
echo "Installing zram..."
sudo pacman -S --noconfirm --needed zram-generator

echo
echo "Setup zram-generator..."
[ -f /etc/systemd/zram-generator.conf ] && sudo cp /etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf.bak
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

echo
echo "Checking zram..."
swapon --summary

echo
echo "Setup gaming for intel archlinux complete!"
