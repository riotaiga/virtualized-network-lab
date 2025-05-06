#!/bin/bash
apt-get update
apt-get install -y net-tools

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Configure static IPs via netplan
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: no
      addresses: [192.168.4.1/24]
    enp0s9:
      dhcp4: true
      dhcp4: true
EOF

netplan generate && netplan apply

# Setup NAT
iptables -t nat -A POSTROUTING -o enp0s10 -j MASQUERADE
iptables -A FORWARD -i enp0s8 -o enp0s10 -j ACCEPT

sleep 10
ip route show
echo "~* Router is ready *~"
 