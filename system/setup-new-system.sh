#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora 44 post-install setup. Review package availability before running.
PACKAGES=(
    ripgrep
    fzf
    less
    jq
    inxi
    openssh-clients
    google-noto-sans-fonts
    google-noto-emoji-fonts
    duf
    neovim
    tree-sitter-cli
    tmux
)

command -v dnf >/dev/null 2>&1 || {
    echo "ERROR: This script is intended for Fedora (dnf not found)." >&2
    exit 1
}

printf 'Installing packages from Fedora repositories...\n'
sudo dnf install --setopt=install_weak_deps=False "${PACKAGES[@]}"

printf '\nSetting up SSH key...\n'
if [[ -e "$HOME/.ssh/id_ed25519" || -e "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo "An Ed25519 SSH key already exists; skipping key generation."
else
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
fi

printf '\nSetting up Neovim dotfiles...\n'
if [[ -e "$HOME/.config/nvim" ]]; then
    echo "$HOME/.config/nvim already exists; not overwriting it. Review or back it up before replacing."
else
    git clone --depth 1 https://github.com/gilpra/nvim.git "$HOME/.config/nvim"
fi

printf '\nSetting up dotfiles...\n'
if [[ -e "$HOME/.dotfiles" ]]; then
    echo "$HOME/.dotfiles already exists; not overwriting it."
else
    git clone -b fedora --depth 1 https://github.com/gilpra/dotfiles.git "$HOME/.dotfiles"
fi

mkdir -p "$HOME/Games"

printf '\nSetting up tmux...\n'
if [[ ! -e "$HOME/.tmux.conf" ]]; then
    curl -fL --retry 3 \
        'https://gist.githubusercontent.com/gilpra/148276c20141b185097d34b268d93349/raw/f7d3f5d5c3b80d876c024af00dd3bbeb74412263/.tmux.conf' \
        -o "$HOME/.tmux.conf"
else
    echo "$HOME/.tmux.conf already exists; not overwriting it."
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo 'tmux Plugin Manager already exists; skipping clone.'
fi

echo "Setup complete."
