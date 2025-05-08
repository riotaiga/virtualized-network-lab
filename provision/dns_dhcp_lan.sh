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
apt-get install -y dnsmasq net-tools openssh-server

# enable and start the SSH service for mgmt server
systemctl enable ssh
systemctl start ssh

# check if the .ssh directory is available
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

# add management server's public key to authorized_keys if it does not exist
if [ -f /vagrant/ssh_keys/mgmt_vagrant_id_rsa.pub ]; then
    cat /vagrant/ssh_keys/mgmt_vagrant_id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys   # read and write only
    chown -R vagrant:vagrant /home/vagrant/.ssh    # making sure vagrant owns the .ssh directory
    echo "Management server public key added to authorized_keys."
else
    echo "Management server public key not found in /vagrant/ssh_keys."
fi

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
