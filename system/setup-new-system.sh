#!/usr/bin/env bash
set -euo pipefail

echo "Installing package..."
sudo pacman -S --needed \
    ripgrep \
    fzf \
    less \
    jq \
    inxi \
    openssh \
    noto-fonts \
    noto-fonts-emoji \
    duf \
    lazygit \
    neovim \
    tree-sitter-cli \
    tmux

echo "Generate ssh key..."
ssh-keygen -t ed25519

echo "Setup neovim with dotfiles..."
rm -rf ~/.config/nvim
git clone --depth 1 https://github.com/gilpra/nvim.git ~/.config/nvim

echo "Install dotfiles..."
rm -rf ~/.dotfiles
git clone --depth 1 https://github.com/gilpra/dotfiles.git ~/.dotfiles

echo "Setup folder..."
mkdir -p ~/Games/

echo "Setup tmux..."
curl https://gist.githubusercontent.com/gilpra/148276c20141b185097d34b268d93349/raw/f7d3f5d5c3b80d876c024af00dd3bbeb74412263/.tmux.conf -o ~/.tmux.conf
rm -rf ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo ""
echo "==========================================================="
echo "Your dotfiles are located in ~/.dotfiles"
echo "To set up your dotfiles, read the README in that directory"
echo "==========================================================="
