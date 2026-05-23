#!/bin/bash

apt-get update

# Pre-seed debconf to prevent interactive prompt from iptables-persistent
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y net-tools openssh-server sshpass iptables-persistent

# Enable the IP forwarding 
sudo sysctl -w net.ipv4.ip_forward=1

# Enable IP forwarding persistently
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

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
      dhcp4: true                           # NAT adapter — keeps vagrant ssh and internet working
    enp0s8:
      dhcp4: no                            
      addresses: [192.168.4.1/24]           # static IP for enp0s8
    enp0s9:
      dhcp4: no
      addresses: [192.168.5.1/24]           # static gateway IP for inet5 network
    enp0s10:                 
      dhcp4: true                           # DHCP for enp0s10  
      routes:
        - to: 0.0.0.0/0                     # specifying the default route 
          via: 192.168.1.1                  # gateway for the enp0s10 
          metric: 99                        # lower metric for higher priority 
EOF

chmod 600 /etc/netplan/*.yaml

# Apply the netplan configuration
netplan generate && netplan apply

# Setup NAT
iptables -t nat -A POSTROUTING -o enp0s10 -j MASQUERADE     # Enable NAT for enp0s10 
iptables -A FORWARD -i enp0s8 -o enp0s10 -j ACCEPT          # Allow traffic from enp0s8 to enp0s10  
iptables -A FORWARD -i enp0s9 -o enp0s10 -j ACCEPT          # Allow traffic from enp0s9 to enp0s10

# Save iptables rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

sleep 10
ip route show

# Fetch mgmt server's public key — runs after netplan so inet5 (enp0s9) has a DHCP IP
MGMT_KEY=$(sshpass -p vagrant ssh \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  vagrant@192.168.5.10 \
  "cat ~/.ssh/id_rsa.pub" 2>/dev/null || true)
if [ -n "$MGMT_KEY" ]; then
  echo "$MGMT_KEY" >> /home/vagrant/.ssh/authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  echo "~* mgmt public key installed — passwordless SSH from mgmt is ready *~"
else
  echo "~* WARNING: could not reach mgmt at 192.168.5.10. Run 'vagrant provision router' after mgmt is up *~"
fi

echo "~* Router is ready *~"
 