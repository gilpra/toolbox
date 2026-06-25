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
# Tambah linux (fallback) + intel-ucode + wireplumber + pipewire-alsa
pacstrap -K /mnt base base-devel \
  linux-zen linux-zen-headers \
  linux-firmware btrfs-progs \
  sudo git networkmanager \
  pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber \
  grub efibootmgr

genfstab -U /mnt >> /mnt/etc/fstab

# === CONFIG SYSTEM ===
arch-chroot /mnt /bin/bash <<EOF
set -Eeuo pipefail

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

# mkinitcpio: tambahkan modul btrfs (aman bila dobel)
if ! grep -q '^MODULES=.*btrfs' /etc/mkinitcpio.conf; then
  sed -i 's/^MODULES=(/MODULES=(btrfs /' /etc/mkinitcpio.conf
fi
mkinitcpio -P

# === USERS & PASSWORDS ===
useradd -m -G wheel -s /bin/bash "$USERNAME"
printf 'root:%s\n' "$ROOT_PASS" | chpasswd
printf '%s:%s\n' "$USERNAME" "$USER_PASS" | chpasswd

# === SUDO CONFIG (wheel group) ===
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/99_wheel
chmod 440 /etc/sudoers.d/99_wheel

# === ENABLE SERVICES ===
systemctl enable NetworkManager
systemctl enable fstrim.timer

# === INSTALL GRUB ===
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# === CLEAR PASSWORD VARIABLE ===
unset ROOT_PASS USER_PASS

echo "==> Installation complete! 🎉 Reboot and login as $USERNAME"
