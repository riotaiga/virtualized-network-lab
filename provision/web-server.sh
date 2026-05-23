#!/bin/bash

apt-get update

# Install Apache web server
apt-get install -y apache2 openssh-server sshpass

# Enable and start Apache service
systemctl enable apache2
systemctl start apache2

# enable and start the ssh service
systemctl enable ssh
systemctl start ssh

# Prepare SSH directory — management server will push the public key directly
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh
echo "Configured .ssh directory; mgmt will install authorized_keys over the network."

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

chmod 600 /etc/netplan/*.yaml

# Apply the netplan configuration
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

# Fetch mgmt server's public key so it can SSH in passwordlessly.
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
  echo "~* WARNING: could not reach mgmt at 192.168.5.10. Run 'vagrant provision webserver' after mgmt is up *~"
fi

echo "~* Web server setup is complete *~"