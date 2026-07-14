#!/usr/bin/env bash

set -Eeuo pipefail

# Helpers
die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() {
  echo
  echo "==> $*"
}
ok() { echo "  [OK] $*"; }
fail() {
  echo "  [FAIL] $*" >&2
  CHECKS_FAILED=1
}
confirm() {
  read -r -p "$1 [y/N] " _ans
  [[ "${_ans,,}" == "y" ]] || die "Aborted by user."
}

# Pre-flight: check required tools
for _cmd in cfdisk mkfs.fat mkfs.btrfs pacstrap arch-chroot genfstab reflector; do
  command -v "$_cmd" &>/dev/null || die "Required tool '$_cmd' not found. Are you running from Arch ISO?"
done

# Optimize mirrorlist with reflector before pacstrap
info "Optimizing mirrorlist with reflector..."
echo "  Fetching fastest mirrors (this may take ~30s)..."
reflector \
  --age 12 \
  --country Indonesia,Singapore \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist \
  --latest 10 && ok "Mirrorlist updated" || {
  echo "  [WARN] reflector failed — continuing with existing mirrorlist"
}

# Partitioning
info "Partition setup"
read -r -p "  Enter disk device (e.g. /dev/nvme0n1): " DISK
[[ -b "$DISK" ]] || die "Disk '$DISK' not found"
cfdisk "$DISK"

read -r -p "  Enter EFI partition (e.g. /dev/nvme0n1p1): " EFI_PART
read -r -p "  Enter Linux root partition (e.g. /dev/nvme0n1p2): " LINUX_PART
[[ -b "$EFI_PART" ]] || die "EFI partition '$EFI_PART' not found"
[[ -b "$LINUX_PART" ]] || die "Linux partition '$LINUX_PART' not found"

# Validate EFI partition size (minimum 100MB)
_efi_size=$(lsblk -b -n -o SIZE "$EFI_PART" 2>/dev/null)
[[ "$_efi_size" -ge 104857600 ]] || die "EFI partition is too small (< 100MB), recommended 300MB+"

# System info
info "System configuration"
read -r -p "  Hostname: " SYS_HOSTNAME
read -r -p "  Timezone (e.g. Asia/Jakarta): " TIMEZONE
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "Invalid timezone '$TIMEZONE'"

read -r -p "  Username: " USERNAME
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username '$USERNAME'"

while true; do
  read -r -s -p "  Root password: " ROOT_PASS
  echo
  if [[ -z "$ROOT_PASS" ]]; then
    echo "  [!] Password cannot be empty, try again."
    continue
  fi
  read -r -s -p "  Confirm root password: " ROOT_PASS2
  echo
  if [[ "$ROOT_PASS" == "$ROOT_PASS2" ]]; then
    break
  fi
  echo "  [!] Passwords do not match, try again."
done

while true; do
  read -r -s -p "  Password for $USERNAME: " USER_PASS
  echo
  if [[ -z "$USER_PASS" ]]; then
    echo "  [!] Password cannot be empty, try again."
    continue
  fi
  read -r -s -p "  Confirm password for $USERNAME: " USER_PASS2
  echo
  if [[ "$USER_PASS" == "$USER_PASS2" ]]; then
    break
  fi
  echo "  [!] Passwords do not match, try again."
done

# Bootloader selection
info "Bootloader selection"
echo "  [1] GRUB         — Universal, multi-OS support, ideal for BTRFS snapshot booting"
echo "  [2] systemd-boot — Simple, fast, UEFI only"
echo
while true; do
  read -r -p "  Choose bootloader [1/2]: " _bl_choice
  case "$_bl_choice" in
  1)
    BOOTLOADER="grub"
    echo "  Bootloader: GRUB"
    break
    ;;
  2)
    BOOTLOADER="systemd-boot"
    echo "  Bootloader: systemd-boot"
    break
    ;;
  *) echo "  [!] Invalid input, enter 1 or 2." ;;
  esac
done

# Final confirmation
echo
echo "  ┌─────────────────────────────────────┐"
echo "  │  Installation summary               │"
echo "  ├─────────────────────────────────────┤"
printf "  │  Disk     : %-23s │\n" "$DISK"
printf "  │  EFI      : %-23s │\n" "$EFI_PART"
printf "  │  Linux    : %-23s │\n" "$LINUX_PART"
printf "  │  Hostname : %-23s │\n" "$SYS_HOSTNAME"
printf "  │  Timezone : %-23s │\n" "$TIMEZONE"
printf "  │  Username : %-23s │\n" "$USERNAME"
printf "  │  Bootloader: %-22s │\n" "$BOOTLOADER"
echo "  └─────────────────────────────────────┘"
echo
confirm "WARNING: All data on $EFI_PART and $LINUX_PART will be DESTROYED. Continue?"

# Format
info "Formatting partitions..."
mkfs.fat -F32 "$EFI_PART"
mkfs.btrfs -f "$LINUX_PART"

# Btrfs subvolumes
info "Creating Btrfs subvolumes..."
mount "$LINUX_PART" /mnt
for _sv in @ @home @log @cache @tmp; do
  btrfs subvolume create "/mnt/$_sv"
  ok "Subvolume $_sv created"
done
umount /mnt

# Mount
info "Mounting subvolumes..."

# Detect if disk is SSD or HDD
_rotational=$(cat "/sys/block/$(lsblk -no PKNAME "$LINUX_PART")/queue/rotational" 2>/dev/null || echo "0")
if [[ "$_rotational" == "0" ]]; then
  _OPTS="noatime,compress=zstd:3,ssd,space_cache=v2,discard=async"
  _OPTS_NOCOW="noatime,nodatacow,ssd,space_cache=v2,discard=async"
  ok "Detected SSD — applying SSD-optimized mount options"
else
  _OPTS="noatime,compress=zstd:3,space_cache=v2"
  _OPTS_NOCOW="noatime,nodatacow,space_cache=v2"
  ok "Detected HDD — applying HDD-compatible mount options"
fi
mount -o "${_OPTS},subvol=@" "$LINUX_PART" /mnt
if [[ "$BOOTLOADER" == "grub" ]]; then
  mkdir -p /mnt/{boot/efi,home,var/log,var/cache,tmp}
  mount -o "${_OPTS},autodefrag,subvol=@home" "$LINUX_PART" /mnt/home
  mount -o "${_OPTS_NOCOW},subvol=@log" "$LINUX_PART" /mnt/var/log
  mount -o "${_OPTS_NOCOW},subvol=@cache" "$LINUX_PART" /mnt/var/cache
  mount -o "${_OPTS_NOCOW},subvol=@tmp" "$LINUX_PART" /mnt/tmp
  mount "$EFI_PART" /mnt/boot/efi
else
  # systemd-boot: ESP mounted directly at /boot
  mkdir -p /mnt/{boot,home,var/log,var/cache,tmp}
  mount -o "${_OPTS},autodefrag,subvol=@home" "$LINUX_PART" /mnt/home
  mount -o "${_OPTS_NOCOW},subvol=@log" "$LINUX_PART" /mnt/var/log
  mount -o "${_OPTS_NOCOW},subvol=@cache" "$LINUX_PART" /mnt/var/cache
  mount -o "${_OPTS_NOCOW},subvol=@tmp" "$LINUX_PART" /mnt/tmp
  mount "$EFI_PART" /mnt/boot
fi

# Base install
info "Running pacstrap (this will take a while)..."
_BOOTLOADER_PKGS=()
[[ "$BOOTLOADER" == "grub" ]] && _BOOTLOADER_PKGS=(grub efibootmgr)

pacstrap -K /mnt \
  base base-devel \
  linux-zen linux-zen-headers \
  linux-firmware btrfs-progs \
  sudo git networkmanager \
  pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber \
  sof-firmware \
  "${_BOOTLOADER_PKGS[@]}"

# fstab
info "Generating fstab..."
genfstab -U /mnt >/mnt/etc/fstab
ok "fstab written"

# chroot block 1 — locale, hostname, initramfs
info "Configuring locale, hostname, initramfs..."
arch-chroot /mnt /bin/bash <<EOF || die "chroot [locale/host/initramfs] failed"
set -Eeuo pipefail

ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "${SYS_HOSTNAME}" > /etc/hostname
{
    echo "127.0.0.1   localhost"
    echo "::1         localhost"
    echo "127.0.1.1   ${SYS_HOSTNAME}.localdomain ${SYS_HOSTNAME}"
} > /etc/hosts

sed -i 's/^MODULES=(/MODULES=(btrfs /' /etc/mkinitcpio.conf
echo "KEYMAP=us" > /etc/vconsole.conf

mkinitcpio -P
EOF

# chroot block 2 — user creation
info "Creating user '$USERNAME'..."
arch-chroot /mnt /bin/bash <<EOF || die "chroot [useradd] failed"
set -Eeuo pipefail
useradd -m -G wheel -s /bin/bash "${USERNAME}"
EOF

# Passwords — piped from outside
info "Setting passwords..."
printf 'root:%s\n' "$ROOT_PASS" | arch-chroot /mnt chpasswd ||
  die "Failed to set root password"
printf '%s:%s\n' "$USERNAME" "$USER_PASS" | arch-chroot /mnt chpasswd ||
  die "Failed to set user password"

# Resolve root PARTUUID outside chroot (blkid needs host /dev)
_ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$LINUX_PART") ||
  die "Failed to resolve PARTUUID for $LINUX_PART"

# chroot block 3 — sudo, services, bootloader
info "Configuring sudo, services, bootloader..."
arch-chroot /mnt /bin/bash <<EOF || die "chroot [services/bootloader] failed"
set -Eeuo pipefail

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/99_wheel
chmod 440 /etc/sudoers.d/99_wheel

systemctl enable NetworkManager
systemctl enable fstrim.timer

systemctl enable systemd-timesyncd

if [[ "${BOOTLOADER}" == "grub" ]]; then
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
else
  # systemd-boot: ESP is already mounted at /boot
  bootctl install

  # Create loader.conf
  cat > /boot/loader/loader.conf <<LOADER
default  arch.conf
timeout  4
console-mode max
editor   no
LOADER

  # Create boot entry for linux-zen
  mkdir -p /boot/loader/entries
  cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux (linux-zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=PARTUUID=${_ROOT_PARTUUID} rootflags=subvol=@ rw
ENTRY

  # Create fallback boot entry
  cat > /boot/loader/entries/arch-fallback.conf <<ENTRY
title   Arch Linux (linux-zen, fallback)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen-fallback.img
options root=PARTUUID=${_ROOT_PARTUUID} rootflags=subvol=@ rw
ENTRY
fi
EOF

# Cleanup
unset ROOT_PASS ROOT_PASS2 USER_PASS USER_PASS2

# Post-install verification
info "Running post-install checks..."
CHECKS_FAILED=0

# fstab validity
if findmnt --verify --tab-file /mnt/etc/fstab &>/dev/null; then
  ok "fstab is valid"
else
  fail "fstab validation failed — run 'findmnt --verify' after reboot"
fi

# EFI bootloader binary & config
if [[ "$BOOTLOADER" == "grub" ]]; then
  if [[ -f /mnt/boot/efi/EFI/GRUB/grubx64.efi ]]; then
    ok "GRUB EFI binary found"
  else
    fail "GRUB EFI binary missing at /boot/efi/EFI/GRUB/grubx64.efi"
  fi

  if [[ -f /mnt/boot/grub/grub.cfg ]]; then
    ok "grub.cfg found"
  else
    fail "grub.cfg missing — grub-mkconfig may have failed"
  fi
else
  if [[ -f /mnt/boot/EFI/systemd/systemd-bootx64.efi ]]; then
    ok "systemd-boot EFI binary found"
  else
    fail "systemd-boot EFI binary missing"
  fi

  if [[ -f /mnt/boot/loader/entries/arch.conf ]]; then
    ok "systemd-boot entry arch.conf found"
  else
    fail "systemd-boot entry missing at /boot/loader/entries/arch.conf"
  fi
fi

# Initramfs images for both kernels
_img=/mnt/boot/initramfs-linux-zen.img
if [[ -f "$_img" ]]; then
  ok "Initramfs present: $(basename "$_img")"
else
  fail "Missing initramfs: $_img"
fi

# User exists
if arch-chroot /mnt id "$USERNAME" &>/dev/null; then
  ok "User '$USERNAME' exists"
else
  fail "User '$USERNAME' not found in chroot"
fi

# Locale generated
if grep -q "^LANG=en_US.UTF-8" /mnt/etc/locale.conf 2>/dev/null; then
  ok "Locale en_US.UTF-8 configured"
else
  fail "Locale may not be configured correctly"
fi

# Enabled services (now including systemd-timesyncd)
for _svc in NetworkManager fstrim.timer systemd-timesyncd; do
  if arch-chroot /mnt systemctl is-enabled "$_svc" &>/dev/null; then
    ok "Service enabled: $_svc"
  else
    fail "Service NOT enabled: $_svc"
  fi
done

# Hostname
if [[ "$(cat /mnt/etc/hostname 2>/dev/null)" == "$SYS_HOSTNAME" ]]; then
  ok "Hostname: $SYS_HOSTNAME"
else
  fail "Hostname mismatch in /etc/hostname"
fi

# /etc/hosts has the 127.0.1.1 entry
if grep -q "127.0.1.1" /mnt/etc/hosts 2>/dev/null; then
  ok "/etc/hosts has 127.0.1.1 entry"
else
  fail "/etc/hosts missing 127.0.1.1 entry"
fi

# Final result
echo
if [[ "$CHECKS_FAILED" -eq 0 ]]; then
  echo "  ✔  All checks passed."
  echo "  ✔  Installation complete — reboot and login as: $USERNAME"
  umount -R /mnt && ok "Filesystems unmounted" || echo "  [WARN] umount failed — run 'umount -R /mnt' manually before rebooting"
else
  echo "  ✘  Installation finished with warnings."
  echo "     Review [FAIL] items above before rebooting."
  echo "     Run 'umount -R /mnt' manually before rebooting."
fi
echo
