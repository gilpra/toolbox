#!/usr/bin/env bash
set -e

echo 'Installing Snapper...'
sudo xbps-install -y snapper

ROOT_DEVICE="$(findmnt -no SOURCE / | sed 's/\[.*//')"
ROOT_UUID="$(findmnt -no UUID /)"

echo 'Creating @snapshots...'
sudo mkdir -p /mnt/btrfs-top
sudo mount -o subvolid=5 "$ROOT_DEVICE" /mnt/btrfs-top
sudo btrfs subvolume create /mnt/btrfs-top/@snapshots
sudo umount /mnt/btrfs-top
sudo rmdir /mnt/btrfs-top

echo 'Creating Snapper root configuration...'
sudo snapper -c root create-config /

# Snapper creates a nested /.snapshots under @.
# Remove it because we use top-level @snapshots instead.
sudo btrfs subvolume delete /.snapshots
sudo mkdir -p /.snapshots

echo "UUID=$ROOT_UUID  /.snapshots  btrfs  noatime,compress=zstd:1,discard=async,subvol=@snapshots  0  0" |
    sudo tee -a /etc/fstab >/dev/null

sudo mount /.snapshots
sudo chmod 750 /.snapshots

sudo snapper -c root set-config \
    TIMELINE_CREATE=no \
    TIMELINE_CLEANUP=no \
    NUMBER_CLEANUP=no

if [[ -d /etc/sv/snapperd ]]; then
    sudo ln -sfn /etc/sv/snapperd /var/service/snapperd
fi

echo
echo 'Snapper setup complete.'
echo
echo 'Layout:'
echo '  @            -> /'
echo '  @home        -> /home'
echo '  @cache       -> /var/cache'
echo '  @log         -> /var/log'
echo '  @snapshots   -> /.snapshots'
echo
echo 'Create a snapshot:'
echo '  sudo snapper -c root create --description "before test"'
echo
echo 'List snapshots:'
echo '  sudo snapper -c root list'
