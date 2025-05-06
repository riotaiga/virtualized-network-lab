#!/bin/bash

# Configure static IPs via netplan
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: no
      addresses: [192.168.4.20/24]
      routes:
        - to: default
          via: 192.168.4.1
      nameservers:
        addresses: [8.8.8.8]
    enp0s9:
      dhcp4: true
EOF

# Set DNS resolver
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# install requred package
apt-get update 
apt-get install -y dnsmasq net-tools
netplan generate
netplan apply
sleep 3 

# Find interface names based on static IPs
INTERFACE4=$(ip -o addr show | awk '/192\.168\.4\.20/ {print $2}')

echo "Interface for 192.168.4.20: $INTERFACE4"
# Configure dnsmasq
cat <<EOF > /etc/dnsmasq.conf 
interface=$INTERFACE4
listen-address=192.168.4.20
bind-interfaces
dhcp-range=192.168.4.100,192.168.4.150,24h
dhcp-option=3,192.168.4.1
dhcp-option=6,192.168.4.20
EOF 

systemctl restart dnsmasq
sleep 5
ip route show
echo "~* dns_dhcp_lan is ready *~"
