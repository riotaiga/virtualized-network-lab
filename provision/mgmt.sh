#!/bin/bash

# Configure static IPs via netplan
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: true 
    enp0s9:
      dhcp4: no
      addresses: [192.168.5.10/24]
      routes:
        - to: default
          via: 192.168.5.1
      nameservers:
        addresses: [8.8.8.8]     
EOF

# Set DNS resolver
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# install requred package
apt-get update 
apt-get install -y dnsmasq net-tools openssh-server
netplan generate
netplan apply
sleep 3 

# Find interface names based on static IP
INTERFACE5=$(ip -o addr show | awk '/192\.168\.5\.10/ {print $2}')
echo "Interface for 192.168.5.10: $INTERFACE5"

# Configure dnsmasq 
cat <<EOF > /etc/dnsmasq.conf
interface=$INTERFACE5
listen-address=192.168.5.10
bind-interfaces
dhcp-range=192.168.5.100,192.168.5.150,24h
dhcp-option=3,192.168.5.1
dhcp-option=6,192.168.5.10
EOF

systemctl restart dnsmasq
sleep 10
cat /etc/dnsmasq.conf  # Make sure it's listening on enp0s9
ip route show
echo "~* mgmt server is ready *~"
