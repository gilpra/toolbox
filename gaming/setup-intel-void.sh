#!/usr/bin/env bash
set -Eeuo pipefail

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '\n==> %s\n' "$*"
}

warn() {
    printf '  [WARN] %s\n' "$*" >&2
}

ok() {
    printf '  [OK] %s\n' "$*"
}

[[ $EUID -ne 0 ]] ||
    die 'Run this script as your normal user; sudo is used for privileged operations.'

command -v sudo >/dev/null 2>&1 ||
    die 'sudo is required.'

command -v xbps-install >/dev/null 2>&1 ||
    die 'xbps-install not found.'

command -v xbps-query >/dev/null 2>&1 ||
    die 'xbps-query not found.'

case "$(uname -m)" in
x86_64) ;;
*)
    die "This gaming setup expects x86_64; detected $(uname -m)."
    ;;
esac

[[ -e /usr/lib/libc.so.6 ]] ||
    die 'This script is intended for a glibc installation.'

info 'Updating Void Linux'
sudo xbps-install -Su

info 'Enabling Void repositories'

# Steam on x86_64 needs multilib. Void's own Steam package documentation
# instructs users to enable both multilib and multilib/nonfree.
sudo xbps-install -y \
    void-repo-nonfree \
    void-repo-multilib \
    void-repo-multilib-nonfree

sudo xbps-install -S

info 'Installing Intel graphics and gaming packages'

sudo xbps-install -y \
    mesa-dri \
    vulkan-loader \
    mesa-vulkan-intel \
    intel-video-accel \
    intel-media-driver \
    gamemode \
    gamescope

info 'Installing 32-bit graphics/runtime libraries'

# These are the generic multilib libraries documented by Void for Steam,
# plus the Intel Vulkan ICD required for 32-bit Vulkan applications.
sudo xbps-install -y \
    libgcc-32bit \
    libstdc++-32bit \
    libdrm-32bit \
    libglvnd-32bit \
    libva-32bit \
    mesa-dri-32bit \
    vulkan-loader-32bit \
    mesa-vulkan-intel-32bit

info 'Refreshing dynamic linker cache'
sudo ldconfig

info 'Installing Steam, Prism Launcher, and Java'

# Steam is packaged in Void's nonfree repository.
sudo xbps-install -y steam

# Steam's package installs its own udev rules. Ensure the current user is
# in video as recommended by Void's Steam package documentation.
if getent group video >/dev/null 2>&1; then
    sudo usermod -aG video "$USER"
    ok "User '$USER' added to video group"
fi

# NTSYNC replacement for Arch's ntsync-autoload.
info 'Configuring NTSYNC when supported by the current Void kernel'

KERNEL_CONFIG="/boot/config-$(uname -r)"

if [[ -r "$KERNEL_CONFIG" ]] && grep -q '^CONFIG_NTSYNC=y$' "$KERNEL_CONFIG"; then
    ok 'NTSYNC is built into the kernel'
elif [[ -r "$KERNEL_CONFIG" ]] && grep -q '^CONFIG_NTSYNC=m$' "$KERNEL_CONFIG"; then
    if sudo modprobe ntsync; then
        printf '%s\n' ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
        ok 'NTSYNC module loaded and configured for boot'
    else
        warn 'Kernel advertises NTSYNC as a module, but modprobe failed.'
    fi
elif modprobe -n ntsync >/dev/null 2>&1; then
    if sudo modprobe ntsync; then
        printf '%s\n' ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
        ok 'NTSYNC module configured for boot'
    else
        warn 'NTSYNC module was found but could not be loaded.'
    fi
elif [[ -e /sys/module/ntsync ]]; then
    ok 'NTSYNC is already active'
else
    warn 'NTSYNC is not available in the current kernel; ntsync-autoload has no direct Void package equivalent.'
fi

# GameMode
info 'Configuring GameMode'

if ! getent group gamemode >/dev/null 2>&1; then
    warn 'The gamemode group was not created by the installed package.'
else
    sudo usermod -aG gamemode "$USER"
    ok "User '$USER' added to gamemode group"
fi

mkdir -p "$HOME/.config"

cat >"$HOME/.config/gamemode.ini" <<'GAMEMODE'
[general]
desiredgov=performance
renice=5
inhibit_screensaver=1
GAMEMODE

info 'Verifying GameMode'

if getent group gamemode | grep -qw "$USER"; then
    ok 'GameMode group membership configured'
else
    warn "User '$USER' is not listed in the gamemode group."
fi

if gamemoded -t >/dev/null 2>&1; then
    ok 'GameMode test passed'
else
    warn 'gamemoded -t did not pass in the current session.'
    warn 'Log out and log back in so the new gamemode/video group membership is active.'
fi

info 'Verifying Vulkan'

if command -v vulkaninfo >/dev/null 2>&1; then
    if vulkaninfo --summary >/dev/null 2>&1; then
        ok 'Vulkan is working'
    else
        warn 'vulkaninfo --summary failed'
    fi
else
    warn 'vulkaninfo is not installed; Vulkan packages are installed but runtime verification is skipped.'
fi

info 'Verifying installed gaming stack'

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

    if xbps-query -l | grep -q "^ii ${pkg}-"; then
        ok "$pkg installed"
    else
        warn "$pkg is missing"
    fi
done

echo
echo 'Gaming setup complete.'
echo
echo 'Installed:'
echo '  Intel Mesa/OpenGL + Vulkan (64-bit and 32-bit)'
echo '  Intel VA-API'
echo '  GameMode'
echo '  Gamescope'
echo '  Steam'
echo
echo 'Useful verification commands:'
echo '  vulkaninfo --summary'
echo '  gamemoded -t'
echo '  glxinfo -B'
echo '  steam'
echo
echo 'Log out and back in after the first run so group membership changes take effect.'
