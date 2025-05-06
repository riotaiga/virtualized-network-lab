#!/bin/bash
apt-get update
apt-get install -y network-manager net-tools

# Use NetworkManager for dynamic IPs
cat <<EOF > /etc/netplan/01-network-manager.yaml
network: 
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s8:
      dhcp4: true 
    enp0s9:
      dhcp4: true
EOF

netplan generate && netplan apply
systemctl restart NetworkManager
sleep 10
ip route show
echo "~* client2 is DHCP-configured from both dns_dhcp_lan amd mgmt*~"
