#!/bin/bash

#install the required packages for software RAID
apt-get update
apt-get install -y mdadm 

# Create the RAID 1 (mirror) with two devices (using /dev/sdb and /dev/sdc)
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc

# Creating filesystem on RAID device
mkfs.ext4 /dev/md0

# Mount RAID device 
mkdir -p /mnt/raid
mount /dev/md0 /mnt/raid

# Add the RAID device to /etc/fstab for automatic mounting on boot
echo "/dev/md0 /mnt/raid ext4 defaults 0 0" >> /etc/fstab

# Save the RAID configuration to mdadm.conf
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u
