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
      dhcp4: no                           # static IP for enp0s8
      addresses: [192.168.4.20/24]        # IP for the DHCP server
      routes:
        - to: 0.0.0.0/0                   # default route
          via: 192.168.4.1                # default gateway  
          metric: 99                      # lower metric for higher priority
      nameservers:
        addresses: [8.8.8.8]              # DNS resolver
    enp0s9:                               # DHCP for enp0s9
      dhcp4: true
EOF

chmod 600 /etc/netplan/*.yaml

# Set DNS resolver
systemctl stop systemd-resolved           # disable systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update

apt-get install -y dnsmasq net-tools openssh-server sshpass

# enable and start the SSH service for mgmt server
systemctl enable ssh
systemctl start ssh

# Prepare SSH directory — management server will push the public key directly
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
echo "Configured .ssh directory; mgmt will install authorized_keys over the network."

# generate and apply netplan configuration
netplan generate
netplan apply

# Wait up to 60s for DHCP lease on inet5 (enp0s9) from mgmt — do NOT use a fixed sleep
for i in $(seq 1 12); do
  ip addr show enp0s9 | grep -q 'inet 192\.168\.5\.' && break
  echo "Waiting for inet5 DHCP lease on enp0s9... ($i/12)"
  sleep 5
done
ip addr show enp0s9
ip route show

# Find network interface for 192.168.4.20
INTERFACE4=$(ip -o addr show | awk '/192\.168\.4\.20/ {print $2}')
echo "Interface for 192.168.4.20: $INTERFACE4"

# Configure dnsmasq for DHCP
cat <<EOF > /etc/dnsmasq.conf 
interface=$INTERFACE4
listen-address=192.168.4.20
bind-interfaces
dhcp-range=192.168.4.100,192.168.4.150,24h
dhcp-option=3,192.168.4.1
dhcp-option=6,192.168.4.20
EOF

# Rstart dnsmasq service
systemctl restart dnsmasq
sleep 5
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
  echo "~* WARNING: could not reach mgmt at 192.168.5.10. Run 'vagrant provision dns_dhcp_lan' after mgmt is up *~"
fi

echo "~* dns_dhcp_lan is ready *~"
