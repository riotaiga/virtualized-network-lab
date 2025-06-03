#!/bin/bash

# Install Apache web server
apt-get update
apt-get install -y apache2 openssh-server

# Enable and start Apache service
systemctl enable apache2
systemctl start apache2

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

# Configure static and DHCP IPs using netplan
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s8:  # Interface for 192.168.4.X (DHCP)
      dhcp4: no
      addresses: [192.168.4.30/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.4.1
          metric: 99
    enp0s9:  # Interface for 192.168.5.X (Static IP)
      dhcp4: yes
EOF

# Apply the netplan configuration
netplan generate
netplan apply

# Confirm network configuration
ip route show

echo "~* Web server setup is complete *~"