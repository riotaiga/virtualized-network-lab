#!/bin/bash

apt-get update

apt-get install -y net-tools openssh-server sshpass

# enable and start the ssh service
systemctl enable ssh
systemctl start ssh

# check if the .ssh directory is available
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

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
      dhcp4: true                  # NAT adapter — keeps vagrant ssh and internet working
    enp0s8:
      dhcp4: true                 
      routes: 
        - to: 0.0.0.0/0            # adding default route   
          via: 192.168.4.1         # gateway for the enp0s8
          metric: 99               # lower metric for higher priority 
    enp0s9:
      dhcp4: true 
EOF

chmod 600 /etc/netplan/*.yaml

# generate and apply netplan configuration
netplan generate && netplan apply

# Wait up to 60s for DHCP lease on inet5 (enp0s9) from mgmt — do NOT use a fixed sleep
for i in $(seq 1 12); do
  ip addr show enp0s9 | grep -q 'inet 192\.168\.5\.' && break
  echo "Waiting for inet5 DHCP lease on enp0s9... ($i/12)"
  sleep 5
done
ip addr show enp0s9
ip route show

# Fetch mgmt server's public key — runs after netplan so inet5 interface is up
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
  echo "~* WARNING: could not reach mgmt at 192.168.5.10. Run 'vagrant provision client1' after mgmt is up *~"
fi

echo "~* client1 is DHCP-configured from both dns_dhcp_lan amd mgmt*~"
