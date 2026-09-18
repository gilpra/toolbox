#!/usr/bin/env bash

set -euo pipefail

if command -v snapper >/dev/null 2>&1; then
    echo "Snapper is already installed"
    exit 0
fi

echo "Installing package..."
sudo pacman -S snapper btrfs-assistant

echo "Configurate subvolume root..."
sudo snapper -c root create-config /

echo "Set permission user for folder snapshot..."
sudo chmod a+rx /.snapshots

echo "Disable snapper timeline service..."
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/root
sudo sed -i 's/^TIMELINE_CLEANUP="yes"/TIMELINE_CLEANUP="no"/' /etc/snapper/configs/root
sudo systemctl disable --now snapper-timeline.timer
