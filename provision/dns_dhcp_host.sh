#!/bin/bash

# Stop and disable systemd-resolved to prevent conflicts with DNS
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Install necessary packages
apt-get update
apt-get install -y dnsmasq net-tools iputils-ping openssh-server
 
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

# Configure static IP and default gateway
ip addr add 192.168.56.20/24 dev enp0s8
ip link set enp0s8 up
ip route add default via 192.168.56.1 dev enp0s8

# Ensuring the interface enp0s8 is configured with a static IP if necessary
#ip addr add 192.168.2.20/24 dev enp0s8
#ip link set enp0s8 up

# Configure the DHCP server to assign addresses in a range
# echo "Configuring dnsmasq..."
# cat <<EOF > /etc/dnsmasq.conf
# interface=enp0s8
# dhcp-range=192.168.1.100,192.168.1.150,12h
# dhcp-option=3,192.168.1.1
# dhcp-option=6,8.8.8.8
# EOF

# Restart dnsmasq service
systemctl restart dnsmasq

# Show the current IP routing and confirm everything is working
ip route show
echo "~* dns_dhcp_host is up with DHCP *~"