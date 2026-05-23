#!/bin/bash
# =============================================================================
# RAID 5 Setup Script
# =============================================================================
#
# WHAT IS RAID 5?
#   RAID 5 stripes data AND parity across 3 or more disks. Parity is a
#   mathematical checksum — if any single disk fails, the missing data can be
#   reconstructed from the remaining disks + parity.
#
#   Example with 4 x 20GB disks:
#     - Usable space = (N-1) x disk_size = 3 x 20GB = 60GB
#     - 1 disk can fail without data loss
#     - Reads are fast (data is spread across disks)
#     - Writes have slight overhead (parity must be calculated)
#
# DISK LAYOUT (VirtualBox):
#   /dev/sda  — primary boot disk (Vagrant OS) — DO NOT TOUCH
#   /dev/sdb  — extra disk 1  ┐
#   /dev/sdc  — extra disk 2  │ These 4 form the RAID 5 array → /dev/md0
#   /dev/sdd  — extra disk 3  │
#   /dev/sde  — extra disk 4  ┘
#
# RESULT:
#   /dev/md0 mounted at /mnt/raid  (ext4, ~60GB usable)
#   Persists across reboots via /etc/fstab and /etc/mdadm/mdadm.conf
#
# =============================================================================

set -e  # exit immediately if any command fails

RAID_DEVICES="/dev/sdb /dev/sdc /dev/sdd /dev/sde"
RAID_ARRAY="/dev/md0"
MOUNT_POINT="/mnt/raid"
NUM_DISKS=4

echo "==> [RAID 5] Starting setup..."

# --- Step 1: Install mdadm (the Linux software RAID tool) -------------------
# mdadm = multiple devices admin. It manages Linux software RAID arrays.
apt-get update -qq
apt-get install -y mdadm --no-install-recommends

# --- Step 2: Verify all 4 disks exist before proceeding --------------------
echo "==> [RAID 5] Checking disks..."
for disk in $RAID_DEVICES; do
  if [ ! -b "$disk" ]; then
    echo "ERROR: $disk not found. Make sure all 4 extra disks are attached in the Vagrantfile."
    exit 1
  fi
  echo "  Found: $disk ($(lsblk -dno SIZE $disk))"
done

# --- Step 3: Tear down any previous RAID state on these disks ---------------
# This makes the script safe to re-run (idempotent).
echo "==> [RAID 5] Cleaning up any previous RAID state..."
umount -f "$MOUNT_POINT" 2>/dev/null || true
mdadm --stop "$RAID_ARRAY" 2>/dev/null || true

# Zero-superblock wipes RAID metadata from each disk.
# Without this, mdadm refuses to reuse a disk that was already in an array.
for disk in $RAID_DEVICES; do
  mdadm --zero-superblock --force "$disk" 2>/dev/null || true
done

# Wipe any leftover partition table or filesystem signatures
for disk in $RAID_DEVICES; do
  wipefs -a "$disk" 2>/dev/null || true
done

# --- Step 4: Create the RAID 5 array ----------------------------------------
# --create          : build a new array
# --verbose         : show what mdadm is doing
# --level=5         : RAID 5 (striping with parity)
# --raid-devices=4  : number of member disks
# --assume-clean    : skip the initial parity sync (safe for a fresh lab, saves time)
echo "==> [RAID 5] Creating RAID 5 array on: $RAID_DEVICES"
mdadm --create --verbose "$RAID_ARRAY" \
  --level=5 \
  --raid-devices=$NUM_DISKS \
  --assume-clean \
  $RAID_DEVICES

# --- Step 5: Wait until the array is active (not just assembling) -----------
echo "==> [RAID 5] Waiting for array to become active..."
for i in $(seq 1 30); do
  STATE=$(cat /sys/block/md0/md/array_state 2>/dev/null || echo "unknown")
  if [ "$STATE" = "active" ] || [ "$STATE" = "clean" ]; then
    echo "  Array state: $STATE — ready"
    break
  fi
  echo "  Array state: $STATE — waiting... ($i/30)"
  sleep 2
done

# Show the final array status so you can verify
echo "==> [RAID 5] Array details:"
mdadm --detail "$RAID_ARRAY"
cat /proc/mdstat

# --- Step 6: Create a filesystem on the RAID array -------------------------
# The RAID array appears as a single block device (/dev/md0).
# We format it with ext4 — a reliable, widely-used Linux filesystem.
echo "==> [RAID 5] Formatting $RAID_ARRAY with ext4..."
mkfs.ext4 -F "$RAID_ARRAY"

# --- Step 7: Mount the array -----------------------------------------------
echo "==> [RAID 5] Mounting $RAID_ARRAY at $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"
mount "$RAID_ARRAY" "$MOUNT_POINT"

# Verify it's mounted and show available space
df -h "$MOUNT_POINT"

# --- Step 8: Persist the mount across reboots (fstab) ----------------------
# 'nofail' means the system still boots even if the RAID array has a problem.
if ! grep -q "$RAID_ARRAY" /etc/fstab; then
  echo "$RAID_ARRAY  $MOUNT_POINT  ext4  defaults,nofail  0  0" >> /etc/fstab
  echo "==> [RAID 5] Added $RAID_ARRAY to /etc/fstab"
fi

# --- Step 9: Save RAID configuration so it reassembles on boot -------------
# mdadm.conf tells the system which disks belong to which array.
# Without this, the array may not auto-assemble after a reboot.
mkdir -p /etc/mdadm
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u   # rebuild initramfs so the RAID config is included in early boot

echo ""
echo "==> [RAID 5] Setup complete!"
echo "    Array  : $RAID_ARRAY"
echo "    Disks  : $RAID_DEVICES"
echo "    Mount  : $MOUNT_POINT"
echo "    Space  : $(df -h $MOUNT_POINT | awk 'NR==2{print $2}') total, $(df -h $MOUNT_POINT | awk 'NR==2{print $4}') free"
echo "    Status : $(cat /sys/block/md0/md/array_state)"
