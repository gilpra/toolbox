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

# === FORMAT & MOUNT ===
mkfs.fat -F32 "$PATH_BOOT"
mkfs.btrfs -f "$PATH_LINUX"

mount "$PATH_LINUX" /mnt

# Buat subvolume (tanpa snapshots)
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp
umount /mnt

# Mount subvolumes
mount -o noatime,compress=zstd:3,subvol=@       "$PATH_LINUX" /mnt
mkdir -p /mnt/{boot/efi,home,var/log,var/cache,tmp,var/lib}

mount -o noatime,compress=zstd:3,autodefrag,subvol=@home   "$PATH_LINUX" /mnt/home
mount -o noatime,compress=zstd:3,subvol=@log               "$PATH_LINUX" /mnt/var/log
mount -o noatime,compress=zstd:3,subvol=@cache             "$PATH_LINUX" /mnt/var/cache
mount -o noatime,compress=zstd:3,subvol=@tmp               "$PATH_LINUX" /mnt/tmp
mount "$PATH_BOOT" /mnt/boot/efi

# === BASE INSTALL ===
pacstrap -K /mnt base base-devel \
  linux-zen linux-zen-headers \
  linux-firmware btrfs-progs \
  sudo git networkmanager \
  pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber \
  grub efibootmgr

genfstab -U /mnt >> /mnt/etc/fstab
