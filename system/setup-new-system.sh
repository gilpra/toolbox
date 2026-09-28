#!/usr/bin/env bash
set -Eeuo pipefail

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '\n==> %s\n' "$*"
}

ok() {
    printf '  [OK] %s\n' "$*"
}

command -v sudo >/dev/null 2>&1 || die 'sudo is required.'
command -v xbps-install >/dev/null 2>&1 || die 'xbps-install not found.'
command -v git >/dev/null 2>&1 || die 'git is required for cloning dotfiles.'

info 'Updating Void Linux'
sudo xbps-install -Su

info 'Installing system and development tools'

sudo xbps-install -y \
    git \
    curl \
    ripgrep \
    fzf \
    less \
    jq \
    inxi \
    openssh \
    noto-fonts-ttf \
    noto-fonts-emoji \
    duf \
    lazygit \
    neovim \
    tree-sitter-cli \
    tmux

info 'Setting up SSH key'

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
else
    ok 'Existing ~/.ssh/id_ed25519 found; skipping key generation.'
fi

info 'Setting up Neovim'

rm -rf "$HOME/.config/nvim"
git clone --depth 1 https://github.com/gilpra/nvim.git "$HOME/.config/nvim"

info 'Installing dotfiles'

rm -rf "$HOME/.dotfiles"
git clone --depth 1 https://codeberg.org/gilpra/dotfiles.git "$HOME/.dotfiles"

info 'Creating Games directory'

mkdir -p "$HOME/Games"

info 'Setting up tmux'

curl -fL \
    https://gist.githubusercontent.com/gilpra/148276c20141b185097d34b268d93349/raw/f7d3f5d5c3b80d876c024af00dd3bbeb74412263/.tmux.conf \
    -o "$HOME/.tmux.conf"

rm -rf "$HOME/.tmux/plugins/tpm"
git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

echo
echo '==========================================================='
echo "Your dotfiles are located in $HOME/.dotfiles"
echo 'To set up your dotfiles, read the README in that directory'
echo '==========================================================='
