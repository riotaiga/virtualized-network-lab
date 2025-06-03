#!/bin/bash

# Update and install packages
apt-get update
apt-get install -y network-manager net-tools openssh-server mysql-server

# Enable services
systemctl enable mysql
systemctl start mysql
systemctl enable ssh
systemctl start ssh

# SSH key setup for vagrant user
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

if [ -f /vagrant/ssh_keys/mgmt_vagrant_id_rsa.pub ]; then
    cat /vagrant/ssh_keys/mgmt_vagrant_id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
    echo "Management server public key added to authorized_keys."
else
    echo "Management server public key not found in /vagrant/ssh_keys."
fi

# Configure static IPs with NetworkManager
cat <<EOF > /etc/netplan/01-network-manager.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s8:
      dhcp4: no
      addresses: [192.168.4.50/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.4.1
          metric: 99
    enp0s9:
      dhcp4: no
      addresses: [192.168.5.50/24]
EOF

netplan generate && netplan apply
systemctl restart NetworkManager
sleep 10

ip route show
echo "Network configuration for database has been applied."