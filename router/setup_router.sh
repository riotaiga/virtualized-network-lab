#!/bin/bash 

#################################
# Script: setup_router.sh 
# Configure the router VM to enable the IP forwarding (allow 
# data packets to move between different networks) and 
# and setting up NAT (allow multiple device on private network
# to share the single public IP address)
#################################

# Enable IP forwarding 
echo "~* Enabling the IP forwarding (please enter password) *~"
sudo sysctl -w net.ipv4.ip_forward=1

# Make IP forwarding persistent across reboots (adding line to end of the file)
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf 

# Set up NAT using iptables 
echo "~* Setting up NAT using iptables (please enter password) *~"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Saving iptables rules 
sudo apt-get update
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save

echo "Router configuration is now complete."