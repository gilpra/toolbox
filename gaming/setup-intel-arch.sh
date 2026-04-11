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
sudo pacman -S --noconfirm --needed mesa vulkan-intel intel-media-driver intel-ucode
