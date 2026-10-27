#!/usr/bin/env bash
set -Eeuo pipefail

command -v dnf >/dev/null 2>&1 || {
    echo 'ERROR: This script is intended for Fedora (dnf not found).' >&2
    exit 1
}

if ! command -v snapper >/dev/null 2>&1; then
    echo 'Installing Snapper and Btrfs tools...'
    sudo dnf install --setopt=install_weak_deps=False snapper btrfs-progs
else
    echo 'Snapper is already installed.'
fi

if ! findmnt -n -t btrfs / >/dev/null 2>&1; then
    echo 'ERROR: / is not mounted from Btrfs. Snapper root configuration was not created.' >&2
    exit 1
fi

if sudo snapper list-configs | awk 'NR > 1 {print $1}' | grep -qx root; then
    echo "Snapper configuration 'root' already exists; leaving it unchanged."
else
    if [[ -e /.snapshots ]]; then
        echo 'ERROR: /.snapshots already exists. Inspect it before creating Snapper configuration:' >&2
        echo '  ls -la /.snapshots' >&2
        echo '  sudo btrfs subvolume list /' >&2
        exit 1
    fi
    echo 'Creating Snapper root configuration...'
    sudo snapper -c root create-config /
fi

CONFIG=/etc/snapper/configs/root
if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Expected Snapper config not found: $CONFIG" >&2
    exit 1
fi

# Manual snapshots only: disable timeline creation and cleanup.
sudo sed -i \
    -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' \
    -e 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="no"/' \
    "$CONFIG"

# Disable the timeline timer only if the unit exists/is enabled.
if systemctl list-unit-files snapper-timeline.timer --no-legend | grep -q snapper-timeline.timer; then
    sudo systemctl disable --now snapper-timeline.timer || true
fi
