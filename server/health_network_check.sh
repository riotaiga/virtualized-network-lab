#!bin/bash 

# network_health_check.sh: 
# checks uptime, disk usage and network connectivity 

echo "~* Server Uptime: *~"
uptime 

echo "~* Disk Usage *~" 
df -h 

echo "~* Ping Test to Router (192.168.56.1): *~"
ping -c 3 192.168.56.1
