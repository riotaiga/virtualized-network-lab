#!/bin/bash

# Wipe all existing netplan files so Vagrant's 50-vagrant.yaml doesn't conflict
# with our config. Include enp0s3 (NAT adapter) so vagrant ssh and internet still work.
rm -f /etc/netplan/*.yaml
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true                           # NAT adapter — keeps vagrant ssh and internet working
    enp0s8:
      dhcp4: no                             # static IP for enp0s8
      addresses: [192.168.56.10/24]         # IP for host-only network
      routes:
        - to: 0.0.0.0/0                     # default route for enp0s8          
          via: 192.168.56.1                 # default gateway for host-only network
          metric: 200                       # high metric — NAT adapter (metric 100) wins for internet
      nameservers:
        addresses: [8.8.8.8]                # DNS resolver
    enp0s9:
      dhcp4: no                             # static IP for enp0s9 (acts as DHCP server)              
      addresses: [192.168.5.10/24]          # IP for mgmt network
EOF

chmod 600 /etc/netplan/*.yaml

# Apply netplan NOW so enp0s3 NAT and DNS are ready before apt runs
netplan generate
netplan apply
sleep 5   # give NAT a moment to fully establish

# Set DNS resolver
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

until ping -c1 -W5 8.8.8.8 > /dev/null 2>&1; do
  echo "Waiting for internet connectivity..."
  sleep 5
done

apt-get update

# install required packages
apt-get install -y dnsmasq net-tools openssh-server

# Enable and start the SSH service for mgmt server 
systemctl enable ssh
systemctl start ssh

# Enable password auth so other VMs can use sshpass to pull this public key
# Ubuntu 24.04 puts overrides in /etc/ssh/sshd_config.d/*.conf (e.g. 60-cloudimg-settings.conf)
# so we must patch both the main config and any drop-in files
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
for f in /etc/ssh/sshd_config.d/*.conf; do
  [ -f "$f" ] && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$f"
done
echo "vagrant:vagrant" | chpasswd
systemctl restart ssh

# Call the script for setting up Nagios for monitoring
# bash /vagrant/provision/mgmt-software/nagios.sh

## --- Simplified key generation and push (sequential, easy to understand)
# Generate the SSH key for the vagrant user if it does not exist
sudo -u vagrant bash <<'EOF'
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 2048 -N "" -f /home/vagrant/.ssh/id_rsa
fi
EOF

# Ensure ownership/permissions for the vagrant user's .ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh || true
chmod 600 /home/vagrant/.ssh/id_rsa || true
chmod 644 /home/vagrant/.ssh/id_rsa.pub || true

echo "~* management server SSH public key *~"
cat /home/vagrant/.ssh/id_rsa.pub || true

# generate and apply netplan configuration
netplan generate || true
netplan apply || true
sleep 3

# Find interface names based on static IP
INTERFACE5=$(ip -o addr show | awk '/192\.168\.5\.10/ {print $2}')
echo "Interface for 192.168.5.10: $INTERFACE5"

# Configure dnsmasq (keep existing behavior)
cat <<EOF > /etc/dnsmasq.conf
interface=$INTERFACE5
listen-address=192.168.5.10
bind-interfaces
dhcp-range=192.168.5.100,192.168.5.150,24h
dhcp-option=3,192.168.5.1
dhcp-option=6,192.168.5.10
EOF

systemctl restart dnsmasq || true
sleep 3
cat /etc/dnsmasq.conf || true
ip route show || true

# Each lab VM fetches this public key during its own provisioning.
# That way the key is always present by the time mgmt tries to SSH in.
echo "~* mgmt server is complete — lab VMs will pull this key at their own provision time *~"

