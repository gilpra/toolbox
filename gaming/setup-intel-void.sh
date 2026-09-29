#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Run this script as your normal user."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is required."
    exit 1
fi

if ! command -v xbps-install >/dev/null 2>&1 ||
    ! command -v xbps-query >/dev/null 2>&1; then
    echo "ERROR: This script requires Void Linux (xbps)."
    exit 1
fi

if [[ $(uname -m) != "x86_64" ]]; then
    echo "ERROR: This gaming setup requires x86_64."
    exit 1
fi

if [[ ! -e /usr/lib/libc.so.6 ]]; then
    echo "ERROR: This script requires a glibc installation."
    exit 1
fi

echo
echo "==> Updating Void Linux"
sudo xbps-install -Su

echo
echo "==> Enabling repositories"
sudo xbps-install -y \
    void-repo-nonfree \
    void-repo-multilib \
    void-repo-multilib-nonfree

sudo xbps-install -S

echo
echo "==> Installing Intel graphics and gaming packages"
sudo xbps-install -y \
    mesa-dri \
    vulkan-loader \
    mesa-vulkan-intel \
    intel-video-accel \
    intel-media-driver \
    gamemode \
    gamescope \
    steam

echo
echo "==> Installing 32-bit libraries"
sudo xbps-install -y \
    libgcc-32bit \
    libstdc++-32bit \
    libdrm-32bit \
    libglvnd-32bit \
    libva-32bit \
    mesa-dri-32bit \
    vulkan-loader-32bit \
    mesa-vulkan-intel-32bit

echo
echo "==> Configuring user groups"

if getent group video >/dev/null; then
    sudo usermod -aG video "$USER"
    echo "[OK] $USER added to video"
fi

if getent group gamemode >/dev/null; then
    sudo usermod -aG gamemode "$USER"
    echo "[OK] $USER added to gamemode"
fi

echo
echo "==> Configuring NTSYNC"

if sudo modprobe ntsync 2>/dev/null; then
    echo ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
    echo "[OK] NTSYNC enabled"
else
    echo "[WARN] NTSYNC is not available in the current kernel."
fi

echo
echo "==> Configuring GameMode"

mkdir -p "$HOME/.config"

cat >"$HOME/.config/gamemode.ini" <<'EOF'
[general]
desiredgov=performance
renice=5
inhibit_screensaver=1
EOF

echo "[OK] GameMode configuration written"

echo
echo "==> Verifying GameMode"

if gamemoded -t >/dev/null 2>&1; then
    echo "[OK] GameMode test passed"
else
    echo "[WARN] GameMode test failed"
    echo "[WARN] Log out and back in after group changes."
fi

echo
echo "==> Verifying Vulkan"

if command -v vulkaninfo >/dev/null 2>&1; then
    if vulkaninfo --summary >/dev/null 2>&1; then
        echo "[OK] Vulkan is working"
    else
        echo "[WARN] vulkaninfo --summary failed"
    fi
else
    echo "[WARN] vulkaninfo is not installed"
fi

echo
echo "==> Verifying installed gaming packages"

for pkg in \
    mesa-dri \
    vulkan-loader \
    mesa-vulkan-intel \
    mesa-dri-32bit \
    vulkan-loader-32bit \
    mesa-vulkan-intel-32bit \
    intel-media-driver \
    gamemode \
    gamescope \
    steam; do

    if xbps-query -S "$pkg" >/dev/null 2>&1; then
        echo "[OK] $pkg installed"
    else
        echo "[WARN] $pkg is missing"
    fi
done

echo
echo "Gaming setup complete."
echo
echo "Useful verification commands:"
echo "  vulkaninfo --summary"
echo "  gamemoded -t"
echo "  glxinfo -B"
echo "  steam"
echo
echo "Log out and back in for group membership changes to take effect."
