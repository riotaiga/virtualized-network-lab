# -*- mode: ruby -*-
# vi: set ft=ruby :
# Using libvirt (KVM/QEMU Emulator) as a Provider instead of VirtualBox due to compatibility issues

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt                   # using libvert (QEMU/KVM) as a provider

  # VM 1: Server (Central Management)
  config.vm.define "server" do |server|
    config.vm.box = "generic/ubuntu2204"        # using ARM compatible Ubuntu box
    server.vm.hostname = "server"               # setting hostname for server
    server.vm.network "private_network", ip: "192.168.56.10" # Assigning IP Address
    server.vm.provider :libvirt do |v|
      v.memory = 1024                           # Allocate 1GB RAM
      v.cpus = 1                                # Allocate 1 CPU
    end
  end

  # VM 2: Client #1
  config.vm.define "client1" do |client|
    config.vm.box = "generic/ubuntu2204"        # using ARM compatible Ubuntu box
    client.vm.hostname = "client1"              # setting hostname for client1
    client.vm.network "private_network", ip: "192.168.56.11" # Assigning IP Address
    client.vm.provider :libvirt do |v|
      v.memory = 512                            # Allocate 512MB RAM
      v.cpus = 1                                # Allocate 1 CPU
    end
  end

  # VM 3: Client2
  config.vm.define "client2" do |client|
    config.vm.box = "generic/ubuntu2204"        # using ARM compatible Ubuntu box
    client.vm.hostname = "client2"              # setting  hostname for client2
    client.vm.network "private_network", ip: "192.168.56.12"  # Assign IP address
    client.vm.provider :libvirt do |v|
      v.memory = 512                            # Allocate 512MB RAM
      v.cpus = 1                                # Allocate 1 CPU
    end
  end
end
