#!/usr/bin/env bash
set -Eeuo pipefail

command -v dnf >/dev/null 2>&1 || {
    echo 'ERROR: This script is intended for Fedora (dnf not found).' >&2
    exit 1
}

PACKAGES=(
    mesa-dri-drivers
    mesa-vulkan-drivers
    libva-intel-media-driver
    gamemode
    gamescope
)

echo 'Installing Intel graphics and gaming packages from Fedora repositories...'
sudo dnf install --setopt=install_weak_deps=False "${PACKAGES[@]}"

# Fedora's GameMode package declares its own group; add the current user if present.
if getent group gamemode >/dev/null 2>&1; then
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx gamemode; then
        sudo usermod -aG gamemode "$USER"
        echo 'Added user to gamemode group; log out and back in for this to take effect.'
    else
        echo 'User is already a member of the gamemode group.'
    fi
else
    echo 'No gamemode group found; skipping group modification.'
fi

mkdir -p "$HOME/.config"
if [[ ! -e "$HOME/.config/gamemode.ini" ]]; then
    cat > "$HOME/.config/gamemode.ini" <<'GAMEMODE'
[general]
renice=5
inhibit_screensaver=1
GAMEMODE
else
    echo "$HOME/.config/gamemode.ini already exists; not overwriting it."
fi

cat <<'MSG'

Gaming setup complete.
Verify GameMode with:
  gamemoded -t
Use it for a game with:
  gamemoderun <game-command>
MSG

