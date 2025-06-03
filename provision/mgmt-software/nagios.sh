#!/bin/bash

# Install Apache, PHP, and utilities
apt-get update
apt-get install -y apache2 apache2-utils \
  libapache2-mod-php php php-gd wget unzip \
  build-essential libgd-dev curl \
  libmcrypt-dev libssl-dev bc gawk dc

# Create Nagios user and group
id -u nagios &>/dev/null || useradd nagios # creating nagios user if it does not exist
getent group nagcmd || groupadd nagcmd     # creating nagcmd group if it does not exist
usermod -a -G nagcmd nagios                # adding nagios user to nagcmd group     
usermod -a -G nagcmd www-data              # adding www-data user to nagcmd group

# Download and extract the Nagios Core
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.9.tar.gz
tar -xvzf nagios-4.5.9.tar.gz
cd nagios-4.5.9

# Compile and install Nagios
./configure --with-command-group=nagcmd

# compile Nagios
make all
# install binaries, initial script, and configuration files
make install
make install-init
make install-config
make install-commandmode
make install-webconf

# Setup web authentication for nagiosadmin
# PLease delete afterwards since this is not very secure (find other way)
htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin admin123

# Enable Apache CGI and site
a2enmod cgi
a2ensite nagios.conf
systemctl restart apache2

# Setup Nagios systemd service manually (if needed)
if [ ! -f /lib/systemd/system/nagios.service ]; then
cat <<EOF > /lib/systemd/system/nagios.service
[Unit]
Description=Nagios Core Monitoring Daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
ExecStop=/bin/kill -s TERM \$MAINPID
PIDFile=/usr/local/nagios/var/nagios.lock

[Install]
WantedBy=multi-user.target
EOF
fi

# Enable and start Nagios
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nagios
systemctl start nagios

# Install Nagios plugins
cd /tmp
wget https://nagios-plugins.org/download/nagios-plugins-2.4.8.tar.gz
tar -xvzf nagios-plugins-2.4.8.tar.gz
cd nagios-plugins-2.4.8
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make

# install the Nagios plugins
make install

echo "~* Nagios setup is complete *~"
