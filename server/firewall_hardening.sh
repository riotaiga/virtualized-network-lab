#!/bin/bash 

# Scripts harden the firewall rules for Management Server 
echo "~ Flushing exist the iptables rules ~"
iptables -F

echo "~ Setting default policy to DROP ~"
iptables -P INPUT DROP
iptables -P FORWARD DROP 
iptables -P OUTPUT ACCEPT

echo "~ Preparing to allow localhost connections ~" 
iptables -A INPUT -i lo -j ACCEPT

echo "~ Allowing SSH access only from the router (192.168.56.1) ~"
iptables -A INPUT -p tcp -s 192.168.56.1 --dport 22 -j ACCEPT

echo "~ Dropping everything else (default policy already being applied) ~"

echo "~ Saving Firewall Rules... ~"
iptables-save > /etc/iptables/rules.v4

echo "~ Firewall Haredening Completed ~" 
