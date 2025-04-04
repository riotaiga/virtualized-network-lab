# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configure Vagrant to manage virtual machines
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"                        # using ARM compatible Ubuntu

  # VM 1: Server (Central Management)
  config.vm.define "server" do |server|
    server.vm.hostname = "server"                             # Set the hostname for the server VM
    server.vm.network "private_network", ip: "192.168.56.10"  # Assign a private IP address
    server.vm.provider "vmware_desktop" do |vb|               # Configure settings specific to the VMware provider
      vb.memory = 1024                                        # Allocate 1GB RAM
      vb.cpus = 1                                             # Allocate 1 CPU
    end
  end

  # VM 2: Client #1
  config.vm.define "client1" do |client|
    client.vm.hostname = "client1"                            # Set the hostname for Client 1
    client.vm.network "private_network", ip: "192.168.56.11"  # Assign a private IP address
    client.vm.provider "vmware_desktop" do |vb|               # Configure settings specific to the VMware provider
      vb.memory = 512                                         # Allocate 512MB RAM
      vb.cpus = 1                                             # Allocate 1 CPU
    end
  end

  # VM 3: Client #2
  config.vm.define "client2" do |client|
    client.vm.hostname = "client2"                            # Set the hostname for Client 2
    client.vm.network "private_network", ip: "192.168.56.12"  # Assign a private IP address
    client.vm.provider "vmware_desktop" do |vb|               # Configure settings specific to the VMware provider
      vb.memory = 512                                         # Allocate 512MB RAM
      vb.cpus = 1                                             # Allocate 1 CPU
    end
  end
end
