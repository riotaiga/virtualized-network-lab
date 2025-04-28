#!/bin/bash 

##########################################################
# Script: setup_server.sh
# Install and configure the simple web server using nginx

##########################################################

# Updating package lists 
echo "Updating the current packages.." 
sudo apt-get update 

# Installing ngix web server 
echo "Installing nginx.."
sudo apt-get install -y nginx 

# Provide Blueprint of basic HTML page
echo "Providing simple web page.."
echo "<h1>LAN Server Succeeded</h1>" | sudo tee /var/www.html/index.html

# Start nginx and enable when server VM boots 
echo "nginx service is starting.." 
sudo systemctl start nginx 
sudo systemctl enable nginx

echo "Server Configuration is now complete." 