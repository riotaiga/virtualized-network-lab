#!/bin/bash 

# Setting the MySQl root password 
MYSQL_ROOT_PASSWORD="root"

# install the MySQL
apt-get update
apt-get install -y mysql-server

# Enable and start the MySQL service
systemctl enable mysql
systemctl stop mysql

# check if /mnt/raid exists and now updating MySQL configuration to use the new RAID directory 
#sudo sed -i '/^\[mysqld\]/a datadir = /mnt/raid/mysql' /etc/mysql/mysql.conf.d/mysqld.cnf
#sudo sed -i 's|^datadir\s*=.*|datadir = /mnt/raid/mysql|' /etc/mysql/mysql.conf.d/mysqld.cnf
#sudo sed -i 's|^#\?datadir\s*=.*|datadir = /mnt/raid/mysql|' /etc/mysql/mysql.conf.d/mysqld.cnf

if [ -d /mnt/raid ]; then
    echo "RAID mount point /mnt/raid found. Configuring MySQL to use RAID."
    sudo rsync -av /var/lib/mysql/ "/mnt/raid/mysql/"
    sudo chown -R mysql:mysql "/mnt/raid/mysql"
    sudo chmod 700 "/mnt/raid/mysql"
    sudo sed -i 's|^#\?datadir\s*=.*|datadir = /mnt/raid/mysql|' /etc/mysql/mysql.conf.d/mysqld.cnf
else
    echo "RAID mount point /mnt/raid not found. Proceeding with default MySQL data directory."
fi
# Set ownership again
chown -R mysql:mysql /mnt/raid/mysql

# Start MySQL
systemctl start mysql

# Disable apparmor for MySQL
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld
sudo systemctl restart mysql

# Secure MySQL installation and remove annonymous users
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF

# Allow external access for root user
mysql -u root <<EOF
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Create testdb database if it has not been created (later on,, combine with prisma)
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS testdb;
EOF

# update the MySQL configuration to allow the external connection
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Restarting the MySQL service
systemctl restart mysql

# Confirm the MySQL datadir
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW VARIABLES LIKE 'datadir';" | grep /mnt/raid/mysql

echo "MySQL setup is complete."