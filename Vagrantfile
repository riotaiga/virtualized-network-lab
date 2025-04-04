# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# # -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Using VirtualBox as the provider
  config.vm.provider "virtualbox"                 # Specify VirtualBox as the provider

  # VM 1: Server (Central Management)
  config.vm.define "server" do |server|
    server.vm.box = "generic/ubuntu2204"          # Using ARM compatible Ubuntu box
    server.vm.hostname = "server"                 # Setting hostname for the server
    server.vm.network "private_network", ip: "192.168.56.10" # Assigning IP Address
    server.vm.provider "virtualbox" do |vb|
      vb.memory = 1024                             # Allocate 1GB RAM
      vb.cpus = 1                                  # Allocate 1 CPU
    end
  end

  # VM 2: Client #1
  config.vm.define "client1" do |client|
    client.vm.box = "generic/ubuntu2204"          # Using ARM compatible Ubuntu box
    client.vm.hostname = "client1"                # Setting hostname for client1
    client.vm.network "private_network", ip: "192.168.56.11" # Assigning IP Address
    client.vm.provider "virtualbox" do |vb|
      vb.memory = 512                              # Allocate 512MB RAM
      vb.cpus = 1                                  # Allocate 1 CPU
    end
  end

  # VM 3: Client #2
  config.vm.define "client2" do |client|
    client.vm.box = "generic/ubuntu2204"          # Using ARM compatible Ubuntu box
    client.vm.hostname = "client2"                # Setting hostname for client2
    client.vm.network "private_network", ip: "192.168.56.12" # Assign IP Address
    client.vm.provider "virtualbox" do |vb|
      vb.memory = 512                              # Allocate 512MB RAM
      vb.cpus = 1                                  # Allocate 1 CPU
    end
  end
end
