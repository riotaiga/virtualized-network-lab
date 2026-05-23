#!/bin/bash

# Stop and disable systemd-resolved to prevent conflicts with DNS
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update

# Install necessary packages
apt-get install -y dnsmasq net-tools iputils-ping openssh-server sshpass
 
# enable and start the ssh service
systemctl enable ssh
systemctl start ssh

# Prepare SSH directory — management server will push the public key directly
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
echo "Configured .ssh directory; mgmt will install authorized_keys over the network."

# Wipe all existing netplan files so Vagrant's 50-vagrant.yaml doesn't conflict
# with our config. Include enp0s3 (NAT adapter) so vagrant ssh and internet still work.
rm -f /etc/netplan/*.yaml
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true                     # NAT adapter — keeps vagrant ssh and internet working
    enp0s8:
      dhcp4: no
      addresses: [192.168.56.20/24]   # static IP for host-only network
EOF

chmod 600 /etc/netplan/*.yaml
netplan generate && netplan apply
sleep 10
ip route show

# Fetch mgmt server's public key so it can SSH in passwordlessly.
# dns_dhcp_host is on the host-only network so it reaches mgmt via 192.168.56.10.
MGMT_KEY=$(sshpass -p vagrant ssh \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  vagrant@192.168.56.10 \
  "cat ~/.ssh/id_rsa.pub" 2>/dev/null || true)
if [ -n "$MGMT_KEY" ]; then
  echo "$MGMT_KEY" >> /home/vagrant/.ssh/authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  echo "~* mgmt public key installed — passwordless SSH from mgmt is ready *~"
else
  echo "~* WARNING: could not reach mgmt at 192.168.56.10. Run 'vagrant provision dns_dhcp_host' after mgmt is up *~"
fi

# IP is now configured via netplan above (persistent across reboots)

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