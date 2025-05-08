#!/bin/bash
apt-get update
apt-get install -y net-tools openssh-server

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# enable and start the ssh service
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
    enp0s10:                 
      dhcp4: true
EOF

netplan generate && netplan apply

# Setup NAT
iptables -t nat -A POSTROUTING -o enp0s10 -j MASQUERADE
iptables -A FORWARD -i enp0s8 -o enp0s10 -j ACCEPT
iptables -A FORWARD -i enp0s9 -o enp0s10 -j ACCEPT

# Save iptables rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

sleep 10 
ip route show

# Disable the interface to prevent accidental use
#ip link set enp0s3 down

echo "~* Router is ready *~"
 