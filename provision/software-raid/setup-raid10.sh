#!/bin/bash

# Install the required packages for software RAID
apt-get update
apt-get install -y mdadm

# Create the RAID 10 (mirroring and striping) with four devices (e.g., /dev/sdb, /dev/sdc, /dev/sdd, /dev/sde)
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Create a filesystem on the RAID device
mkfs.ext4 /dev/md0

# Mount the RAID device
mkdir -p /mnt/raid
mount /dev/md0 /mnt/raid

# Add the RAID device to /etc/fstab for automatic mounting on boot
echo "/dev/md0 /mnt/raid ext4 defaults 0 0" >> /etc/fstab

# Save the RAID configuration to mdadm.conf
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u