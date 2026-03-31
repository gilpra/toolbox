#!/usr/bin/env bash
set -Eeuo pipefail

# === UTIL ===
die() { echo "ERROR: $*" >&2; exit 1; }

# === PARTITIONING ===
echo "==> Run cfdisk to create partitions (EFI + Linux)"
read -r -p "Insert disk (example: /dev/nvme0n1): " DISK
[[ -b "$DISK" ]] || die "Disk $DISK not found"
cfdisk "$DISK"

# Setelah keluar dari cfdisk, user inputkan path partisi
read -r -p "Input your EFI Filesystem Partition (example: /dev/nvme0n1p1): " PATH_BOOT
read -r -p "Input your Linux System Partition (example: /dev/nvme0n1p2): " PATH_LINUX
[[ -b "$PATH_BOOT" ]]  || die "EFI partition $PATH_BOOT not found"
[[ -b "$PATH_LINUX" ]] || die "Linux partition $PATH_LINUX not found"

read -r -p "Input hostname: " HOSTNAME
read -r -p "Input timezone (example: Asia/Jakarta): " TIMEZONE
read -r -p "Enter new username: " USERNAME
read -r -s -p "Set root password: " ROOT_PASS;  echo
read -r -s -p "Set password for $USERNAME: " USER_PASS; echo
