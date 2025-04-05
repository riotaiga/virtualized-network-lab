# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configure Vagrant to manage virtual machines
Vagrant.configure("2") do |config|

  # VM 1: Server (Central Management)
  config.vm.define "server" do |server|
    server.vm.box = "vann/ubuntu-22.04-arm64"
    server.vm.box_version = "0.0.3"
    server.vm.hostname = "server"                             # Set the hostname for the server VM
    server.vm.network "private_network", ip: "192.168.56.10"  # Assign a private IP address
    server.vm.provider "vmware_desktop" do |vmware|           # Configure settings specific to the VMware provider
      vmware.memory = 1024                                    # Allocate 1GB RAM
      vmware.cpus = 1                                         # Allocate 1 CPU
      vmware.allowlist_verified = true
    end
  end

  # VM 2: Client #1
  config.vm.define "client1" do |client|
    client.vm.box = "vann/ubuntu-22.04-arm64"
    client.vm.box_version = "0.0.3"
    client.vm.hostname = "client1"                            # Set the hostname for Client 1
    client.vm.network "private_network", ip: "192.168.56.11"  # Assign a private IP address
    client.vm.provider "vmware_desktop" do |vmware|           # Configure settings specific to the VMware provider
      vmware.memory = 1024                                    # Allocate 512MB RAM
      vmware.cpus = 1                                         # Allocate 1 CPU
      vmware.allowlist_verified = true                        # Enable the use of verified boxes·
    end
  end

  # VM 3: Client #2
  config.vm.define "client2" do |client|
    client.vm.box = "vann/ubuntu-22.04-arm64"
    client.vm.box_version = "0.0.3"
    client.vm.hostname = "client2"                            # Set the hostname for Client 2
    client.vm.network "private_network", ip: "192.168.56.12"  # Assign a private IP address
    client.vm.provider "vmware_desktop" do |vmware|           # Configure settings specific to the VMware provider
      vmware.memory = 1024                                    # Allocate 512MB RAM
      vmware.cpus = 1                                         # Allocate 1 CPU
      vmware.allowlist_verified = true                        # Enable the use of verified boxes
    end
  end

  # VM 4: Client #3
  config.vm.define "client3" do |client|
    client.vm.box = "vann/ubuntu-22.04-arm64"
    client.vm.box_version = "0.0.3"
    client.vm.hostname = "client3"                            # Set the hostname for Client 3
    client.vm.network "private_network", ip: "192.168.56.13"  # Assign a private IP address
    client.vm.provider "vmware_desktop" do |vmware|           # Configure sertings specific to the VMware provider
      vmware.memory = 1024                                    # Allocate 512MB RAM
      vmware.cpus = 1                                         # Allocate 1 CPU
      vmware.allowlist_verified = true                        # Enable the use of verified boxes
    end
  end
end
