#!/bin/nash 

# nat_port_forwarding.sh:
# Simulating NAT and port forwarding from ecternal to internal clients 
echo "~* Enable the IP forwarding *~"
echo 1 > /proc/sys/net/ipv4/ip_forward 

echo "~* Configuring NAT... *~"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

echo "~* Forwarding external port 8080 to client1 port 80... *~"
ip tables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.56.11:80