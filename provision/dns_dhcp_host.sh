#!/bin/bash

# Stop and disable systemd-resolved to prevent conflicts with DNS
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Install necessary packages
apt-get update
apt-get install -y dnsmasq net-tools iputils-ping

# Configure network interfaces
echo "Configuring enp0s8 (public network)..."
# Ensuring the interface enp0s8 is configured with a static IP if necessary
ip addr add 192.168.2.20/24 dev enp0s8
ip link set enp0s8 up

# Configure the DHCP server to assign addresses in a range
echo "Configuring dnsmasq..."
cat <<EOF > /etc/dnsmasq.conf
interface=enp0s8
dhcp-range=192.168.2.100,192.168.2.150,12h
dhcp-option=3,192.168.2.1
dhcp-option=6,8.8.8.8
EOF  

# Restart dnsmasq service
systemctl restart dnsmasq

# Show the current IP routing and confirm everything is working
ip route show
echo "~* dns_dhcp_host is up with DHCP *~"