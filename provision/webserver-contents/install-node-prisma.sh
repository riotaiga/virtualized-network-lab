#!/bin/bash
# This script installs Node.js and Prisma CLI on a web server.

echo "~* Installing Node.js *~"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "~* Istalling global Prisma CLI and mysql client... *~"
npm install -g prisma
apt-get install -y mysql-client

# Install net tools
apt-get install -y net-tools

echo "#############################################"
echo "Node.js and Prisma CLI installation complete."
echo "#############################################"