#!/bin/bash

# Define RAID devices and mount point
RAID_DEVICES="/dev/sdc /dev/sdd /dev/sde /dev/sdf"
RAID_ARRAY="/dev/md0"
MOUNT_POINT="/mnt/raid"
RAID_LEVEL=5

# Stop and remove any existing RAID array
umount -f "$MOUNT_POINT" || true
mdadm --stop "$RAID_ARRAY" || true
mdadm --remove "$RAID_ARRAY" || true

# Clear old RAID metadata
echo "Clearing old RAID metadata..."
for disk in $RAID_DEVICES; do
    mdadm --zero-superblock --force "$disk" || true
done

# Create the RAID 5 array
echo "Creating RAID 5 array with devices: $RAID_DEVICES"
mdadm --create --verbose "$RAID_ARRAY" --level="$RAID_LEVEL" --raid-devices=$(echo $RAID_DEVICES | wc -w) $RAID_DEVICES

# Wait for RAID synchronization to complete
echo "Waiting for RAID synchronization to complete..."
while [ "$(cat /proc/mdstat | grep -c md0)" -eq 0 ]; do
    cat /proc/mdstat
    sleep 10
done
echo "RAID synchronization completed."

# Update initramfs
sudo update-initramfs -u

# Create a filesystem on the RAID array
mkfs.ext4 "$RAID_ARRAY"

# Mount the RAID array
mkdir -p "$MOUNT_POINT"
mount "$RAID_ARRAY" "$MOUNT_POINT"

# Add to /etc/fstab for persistence
if ! grep -q "$RAID_ARRAY" /etc/fstab; then
    echo "$RAID_ARRAY $MOUNT_POINT ext4 defaults,nofail 0 0" >> /etc/fstab
fi

# Save RAID configuration
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

echo "~* RAID setup is complete *~"