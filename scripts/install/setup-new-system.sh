#!/usr/bin/env bash
set -euo pipefail

echo "Installing package..."
sudo pacman -S --needed ripgrep fzf less jq inxi openssh noto-fonts noto-fonts-emoji duf lazygit

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

echo "Setup folder..."
xdg-user-dirs-update
mkdir -p ~/Projects/Programming/ ~/Games/

echo "Setup tmux..."
sudo pacman -S tmux
curl https://gist.githubusercontent.com/gilpra/148276c20141b185097d34b268d93349/raw/f7d3f5d5c3b80d876c024af00dd3bbeb74412263/.tmux.conf -o ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing firefox..."
sudo pacman -S --needed firefox
