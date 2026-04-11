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

echo
echo "Installing lib32 package..."
sudo pacman -S --noconfirm --needed lib32-mesa lib32-vulkan-intel lib32-vulkan-mesa-layers lib32-freetype2
