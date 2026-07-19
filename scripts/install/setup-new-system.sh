#!/usr/bin/env bash
set -euo pipefail

echo "Installing package..."
sudo pacman -S --needed fish ripgrep fzf less jq inxi openssh noto-fonts noto-fonts-emoji duf

echo "Setup fish shell.."
chsh -s "$(command -v fish)"

echo "Setup ssh for Github..."
ssh-keygen -t ed25519 -C "garpra@github"

echo "Install npm with nvm..."
sudo pacman -S --needed fisher
fish -c "fisher install jorgebucaran/nvm.fish"
fish -c "nvm install lts"
fish -c "set -U nvm_default_version lts"

echo "Setup neovim with dotfiles..."
sudo pacman -S --needed neovim tree-sitter-cli
rm -rf ~/.config/nvim
git clone https://github.com/garpra/nvim.git ~/.config/nvim

if ! command -v yay >/dev/null 2>&1; then
    echo "Installing yay..."

    sudo pacman -S --needed git base-devel

    tmpdir=$(mktemp -d)

    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"

    cd "$tmpdir/yay"
    makepkg -si

    cd
    rm -rf "$tmpdir"
fi

echo "Install sway dotfiles..."
rm -rf ~/.dotfiles/sway-dots
git clone https://github.com/garpra/sway-dots ~/.dotfiles/sway-dots
bash ~/.dotfiles/sway-dots/setup.sh

echo "Installing firefox..."
sudo pacman -S --needed firefox
