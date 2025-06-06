#!/bin/bash
apt-get update
apt-get install -y network-manager net-tools openssh-server

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

# Use NetworkManager for dynamic IPs
cat <<EOF > /etc/netplan/01-network-manager.yaml
network: 
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s8:
      dhcp4: true 
      routes: 
        - to: 0.0.0.0/0           # adding default route        
          via: 192.168.4.1        # gateway for the enp0s8
          metric: 99              # lower metric for higher priority
    enp0s9:
      dhcp4: true
EOF

# generate and apply netplan configuration
netplan generate && netplan apply
systemctl restart NetworkManager

# show the routing table
sleep 10
ip route show
echo "~* client2 is DHCP-configured from both dns_dhcp_lan amd mgmt*~"
