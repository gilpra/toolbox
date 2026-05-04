#!/usr/bin/env bash
set -euo pipefail

if ! nm-online -q; then
    echo "No Internet connection..."

    nmcli radio wifi on
    nmcli device wifi rescan
    nmcli device wifi list

    echo "Enter Wi-Fi name (SSID): "
    read -r wifi_name

    echo "Enter Wi-Fi password: "
    read wifi_pass

    if nmcli device wifi connect "$wifi_name" password "$wifi_pass"; then
        echo "Connection successfully"

        if nm-online -q; then
            echo "Internet available"
        fi
    else
        echo "Failed to connect"
    fi
fi

echo "Installing package..."
sudo pacman -S --needed fish ripgrep fzf less jq inxi openssh noto-fonts noto-fonts-emoji

echo "Setup fish shell.."
chsh -s "$(command -v fish)"
