#!/usr/bin/env bash
set -euo pipefail

echo "Installing package..."
sudo pacman -S --needed ripgrep fzf less jq inxi openssh noto-fonts noto-fonts-emoji duf

echo "Setup ssh for Github..."
ssh-keygen -t ed25519

echo "Setup neovim with dotfiles..."
sudo pacman -S --needed neovim tree-sitter-cli nodejs npm
rm -rf ~/.config/nvim
git clone https://github.com/gilpra/nvim.git ~/.config/nvim

echo "Install sway dotfiles..."
rm -rf ~/.dotfiles/sway-dots
git clone https://github.com/gilpra/sway-dots ~/.dotfiles/sway-dots
bash ~/.dotfiles/sway-dots/setup.sh

echo "Installing firefox..."
sudo pacman -S --needed firefox
