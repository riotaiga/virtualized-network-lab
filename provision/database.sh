#!/bin/bash

apt-get update

# Install packages
apt-get install -y net-tools openssh-server mysql-server sshpass

# Enable services
systemctl enable mysql
systemctl start mysql
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
      dhcp4: true                 # NAT adapter — keeps vagrant ssh and internet working
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

chmod 600 /etc/netplan/*.yaml
netplan generate && netplan apply
sleep 5   # allow kernel to fully bring up static interfaces before SSH attempt

ip route show
echo "Network configuration for database has been applied."

# Fetch mgmt server's public key so it can SSH in passwordlessly.
# mgmt must already be up (it is provisioned first).
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
  echo "~* WARNING: could not reach mgmt at 192.168.5.10. Run 'vagrant provision database' after mgmt is up *~"
fi