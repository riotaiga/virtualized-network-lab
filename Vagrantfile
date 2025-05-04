# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Set variable for box and version 
  BOX_NAME = "bento/ubuntu-20.04"
  BOX_VERSION = "202404.23.0"

  # VM 2: DNS/DHCP Server for 192.168.4.X and 192.168.5.X network 
  config.vm.define "dns_dhcp_lan" do |dns_dhcp_lan|
    dns_dhcp_lan.vm.box = BOX_NAME
    dns_dhcp_lan.vm.box_version = BOX_VERSION
    dns_dhcp_lan.vm.hostname = "dns-dhcp-lan" 
    #dns_dhcp_lan.vm.network "private_network", ip: "192.168.4.20", auto_config: false, id: "dns_dhcp_lan4"
    #dns_dhcp_lan.vm.network "private_network", ip: "192.168.5.20", auto_config: false, id: "dns_dhcp_lan5"
    dns_dhcp_lan.vm.network "private_network", auto_config: false, id: "dns_dhcp_lan4"
    #dns_dhcp_lan.vm.network "private_network", auto_config: false, id: "dns_dhcp_lan5"
    dns_dhcp_lan.vm.provision "shell", inline: <<-SHELL
      # USING HEREDOC 
      cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth1:
      dhcp4: no
      addresses: [192.168.4.20/24]
      routes:
        - to: default
          via: 192.168.4.1
      nameservers:
        addresses: [8.8.8.8]
    # eth2:
    #   dhcp4: no
    #   addresses: [192.168.5.20/24]
EOF

      ip a
      systemctl stop systemd-resolved
      systemctl disable systemd-resolved
      echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
      
      apt-get update 
      apt-get install -y dnsmasq net-tools
      rm /etc/resolv.conf
      ln -s /run/dnsmasq/resolv.conf /etc/resolv.conf
      netplan apply
      echo "############ NETWORK INTERFACE CHECK ##############"
      ip route show
      # Note: please review these commands

      # USING HEREDOC 
      cat <<EOF > /etc/dnsmasq.conf 
# Provide DHCP Configuration
interface=eth1                                                           # provide eth1 for specific interface
listen-address=192.168.4.20  # IP of eth1                                              
#interface=eth2    
#listen-address=192.168.5.20  # IP of eth2                               # provide eth2 for specific interface
bind-interfaces                                                           # to provide no conflict between interfaces

# DHCP for 192.168.4.0/24 
dhcp-range=eth1,192.168.4.100,192.168.4.150,24h            
dhcp-option=eth1,3,192.168.4.1                                            # DHCP option code 3 represents router
dhcp-option=eth1,6,192.168.4.20                                           # DHCP option code 6 represents DNS
   
# DHCP for 192.168.5.0/24 
#dhcp-range=eth2,192.168.5.100,192.168.5.150,24h 
#dhcp-option=eth2,3,192.168.5.1                                            # DHCP option code 3 represents router
#dhcp-option=eth2,6,192.168.5.20                                           # DHCP option code 6 represents DNS 



EOF
      systemctl restart dnsmasq   
      echo "~* DNS/DHCP Server is Ready. *~"
    SHELL
    
    dns_dhcp_lan.vm.provider "virtualbox" do |vb| 
      vb.memory = 1024
      vb.cpus = 1
      vb.allowlist_verified = true
    end
  end

=begin
  # VM 3: DNS/DHCP Server on Host network (dhcp embedded network so use public_network, type: "dhcp" for host network)
  config.vm.define "dns_dhcp_host" do |dns_dhcp_host|
    dns_dhcp_host.vm.box = BOX_NAME
    dns_dhcp_host.vm.box_version = BOX_VERSION
    dns_dhcp_host.vm.hostname = "dns-dhcp-host"

    # Error occurred due to "Network specified with `:hostname` must provide a static ip"
    dns_dhcp_host.vm.network "public_network", type: "dhcp"                       # DHCP embedded network 

    dns_dhcp_host.vm.provision "shell", inline: <<-SHELL
      # Disable systemd-resolved to prevent DNS resolution conflicts
      systemctl stop systemd-resolved
      systemctl disable systemd-resolved
 
      # Manually set Google's public DNS
      echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

      # Update the system and install necessary packages
      apt-get update
      apt-get install -y dnsmasq net-tools

      # Create symlink for DNS configuration
      rm /etc/resolv.conf
      ln -s /run/dnsmasq/resolv.conf /etc/resolv.conf
      echo "~* dns-dhcp-host received the IP through embedded DHCP *~"
    SHELL

    dns_dhcp_host.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
      vb.allowlist_verified = true
    end
  end

  # VM 1: Router
  config.vm.define "router" do |router|
    router.vm.box = BOX_NAME
    router.vm.box_version = BOX_VERSION 
    router.vm.hostname = "router"                                                 # Set the hostname for router

    router.vm.network "private_network", auto_config: false, id: "router4"      # Assign a private IP address
    router.vm.network "private_network", auto_config: false, id: "router5"      # Assign a private IP address
    router.vm.network "public_network", bridge: "en0", auto_config: true          # Assign bridge to connect to internet          
    # Note: Install iptables and figure out how to set the firewall using iptables command
    router.vm.provision "shell", inline: <<-SHELL

#       # USING HEREDOC 
#       cat <<EOF > /etc/netplan/01-netcfg.yaml
# network:
#   version: 2
#   ethernets:
#     eth1:
#       dhcp4: no
#       addresses: [192.168.4.1/24]
#     eth2:
#       dhcp4: no
#       addresses: [192.168.5.1/24]
#     eth3:
#       dhcp4: true
# EOF

      apt-get update
      apt-get install -y iptables

      netplan apply
      echo "############ NETWORK INTERFACE CHECK ##############"
      ip route show
      sleep 10
      echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf                          # Enable IP forwarding to direct network traffic between different networks.
      iptables -t nat -A POSTROUTING -o eth3 -j MASQUERADE                      # Enables internet access for machines on a private network 
      echo "~* Router VM is Ready. *~"
    SHELL

    router.vm.provider "virtualbox" do |vb|                               # Configure settings specific to the vb provider
      vb.memory = 1024                                                        # Allocate 1 GB RAM 
      vb.cpus = 1                                                             # Allocate 1 CPU
      vb.allowlist_verified = true                                            # Enable the use of verified boxes
    end
  end
=begin
  #VM 4: MGMT Server
  config.vm.define "mgmt" do |mgmt|
    mgmt.vm.box = BOX_NAME
    mgmt.vm.box_version = BOX_VERSION
    mgmt.vm.hostname = "mgmt-server"

    # Review this 
    mgmt.vm.network "private_network", auto_config: false, id: "mgmt4"    # explicitly say that it should configured as ip address
    mgmt.vm.network "private_network", auto_config: false, id: "mgmt5"    # explicitly say that it should configured as ip address
    mgmt.vm.network "public_network", bridge: "en0", auto_config: true      # automatically request and receive an IP address from the DHCP Host
    mgmt.vm.provision "shell", inline: <<-SHELL
    # USING HEREDOC 
      cat <<EOF > /etc/netplan/01-netcfg.yaml 
network:
  version: 2
  ethernets:
    eth1:
      dhcp4: no
      addresses: [192.168.4.10/24]
    eth2:
      dhcp4: no
      addresses: [192.168.5.10/24]
      nameservers:
        addresses: [192.168.4.20, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.5.1
    eth3:
      dhcp4: true
EOF

      apt-get update
      apt-get install -y iputils-ping    # provide net-tools package for managing and troubleshooting network
      netplan apply
      echo "############ NETWORK INTERFACE CHECK ##############"
      ip route show                                 
      echo "~* MGMT Server is ready on 192.168.4.10 and 192.168.5.10 *~"
    SHELL

    mgmt.vm.provider "virtualbox" do |vb| 
      vb.memory = 1024
      vb.cpus = 1
      vb.allowlist_verified = true
    end
  end
=end

  #VM 5: Client1 Server for 192.168.4.X and 192.168.5.X network 
  config.vm.define "client1" do |client|
    client.vm.box = BOX_NAME
    client.vm.box_version = BOX_VERSION
    client.vm.hostname = "client1" 
    client.vm.network "private_network", auto_config: false, id: "client1_4"     # manually configure the network interface eth1
    #client.vm.network "private_network", auto_config: false, id: "client1_5"                    # manually configure the network interface eth2

    client.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y network-manager net-tools

      # Fully disable and mask systemd-networkd to prevent interference
      systemctl stop systemd-networkd
      systemctl stop systemd-networkd.socket
      systemctl disable systemd-networkd
      systemctl disable systemd-networkd.socket
      systemctl mask systemd-networkd
      systemctl mask systemd-networkd.socket

      # mask to prevent the activation
      systemctl mask systemd-networkd
      systemctl mask systemd-networkd.socket

      # Clean stale configs
      rm -f /run/systemd/network/*netplan*.network


      # USING HEREDOC
      cat <<EOF > /etc/netplan/01-netcfg.yaml
network: 
    version: 2
    renderer: NetworkManager
    ethernets:
      eth1:
        dhcp4: true
      # eth2: 
      #   dhcp4: true
EOF

      # Bring interfaces up and provide the configuration
      ip link set eth1 up
      #ip link set eth2 up

      # Start NetworkManager before applying Netplan
      systemctl restart NetworkManager

      netplan generate
      netplan apply
      sleep 5

      echo "############ NETWORK INTERFACE CHECK ##############"
      # Output the interface status for verification
      ip addr show eth1
      #ip addr show eth2

      echo "############## ROUTES ##################"
      sleep 5
      ip route show

      # Check status for both systemd-networkd, NetworkManager
      systemctl status systemd-networkd

      echo "~* Client1 VM is ready. *~"
    SHELL

    client.vm.provider "virtualbox" do |vb| 
      vb.memory = 1024
      vb.cpus = 1
      vb.allowlist_verified = true
    end
  end

=begin
  #VM 6: Client2 for 192.168.4.X and 192.168.5.X network
      apt-get update
      #apt-get install -y apache2 net-tools                                        # provide net-tools and apache2 software
  config.vm.define "client2" do |client|
    client.vm.box = BOX_NAME
    client.vm.box_version = BOX_VERSION
    client.vm.hostname = "web-server" 
    client.vm.network "private_network", auto_config: false, id: "client2_4"              # manually configure the network interface eth1
    client.vm.network "private_network", auto_config: false, id: "client2_5"              # manually configure the network interface eth2

    client.vm.provision "shell", inline: <<-SHELL
      # USING HEREDOC
      cat <<EOF > /etc/netplan/01-netcfg.yaml
network: 
  version: 2
  ethernets:
    eth1:
      dhcp4: true
    eth2: 
      dhcp4: true
EOF

      netplan apply
      echo "############ NETWORK INTERFACE CHECK ##############"
      ip route show

      echo "~* Web Server VM is ready. *~"
    SHELL

    client.vm.provider "virtualbox" do |vb| 
      vb.memory = 1024
      vb.cpus = 1
      vb.allowlist_verified = true
    end
  end
=end
end