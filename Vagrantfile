Vagrant.configure("2") do |config|
  ########################################
  # DNS DHCP Host for the hostonly network
  ########################################
  config.vm.define "dns_dhcp_host" do |node|
    node.vm.hostname = "dns-dhcp-host"        # Using Ubuntu 20.04 base box 
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "dns_dhcp_host"               # Name of the VM in VirtualBox
      vb.memory = 512                         # Memory allocated to the VM (512MB RAM)
      vb.cpus = 1                             # 1 CPU allocated to the VM            
    end
    # using static IP address for the host-only network
    node.vm.network :private_network, ip: "192.168.56.20", adapter: 2
    node.vm.provision "shell", path: "provision/dns_dhcp_host.sh"
  end

  ######################
  # Management Server
  ######################
  config.vm.define "mgmt" do |node|
    node.vm.hostname = "mgmt"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "mgmt"
      vb.memory = 1024
      vb.cpus = 1
    end
    # use the static IP address for the host-only network
    node.vm.network :private_network, ip: "192.168.56.10", adapter: 2
    # Internal network (inet5) for DHCP clients, mgmt server will be the DHCP server
    node.vm.network :private_network, ip: "192.168.5.10", auto_config: false, virtualbox__intnet: "inet5", adapter: 3
    node.vm.provision "shell", path: "provision/mgmt.sh"
  end

  ######################
  # Router
  ######################
  config.vm.define "router" do |node|
    node.vm.hostname = "router"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "router"
      vb.memory = 512
      vb.cpus = 1
    end
    # Internal network (inet4), have a static IP address for the router
    node.vm.network :private_network, ip: "192.168.4.1", auto_config: false, virtualbox__intnet: "inet4", adapter: 2
    # Internal network (inet5), gets the IP address from the DHCP server (mgmt server)
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", adapter: 3
    # bridge network to host Wi-Fi network which is used for the router to connect to the internet
    node.vm.network :public_network, bridge: "Intel(R) Wi-Fi 6 AX200 160MHz", auto_config: false, adapter: 4
    node.vm.provision "shell", path: "provision/router.sh"
  end

  ##################
  # DNS DHCP LAN
  ##################
  config.vm.define "dns_dhcp_lan" do |node|
    node.vm.hostname = "dns-dhcp-lan"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "dns_dhcp_lan"
      vb.memory = 1024
      vb.cpus = 1
    end

    # provide static IP address for 192.168.4.0/24 network which will act as a DHCP server
    node.vm.network :private_network, ip: "192.168.4.20", auto_config: false, virtualbox__intnet: "inet4", adapter: 2
    # IP address provided by DHCP server (mgmt server) on 192.168.5.0/24 network 
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", adapter: 3
    node.vm.provision "shell", path: "provision/dns_dhcp_lan.sh"
  end

  ####################
  # Client 1
  ####################
  config.vm.define "client1" do |node|
    node.vm.hostname = "client1"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "client1"
      vb.memory = 512
      vb.cpus = 1
    end

    # Configure the private network with DHCP-assigned IP address from mgmt server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet4", auto_config: false, adapter: 2
    # Configure the private network with DHCP-assigned IP address from dns_dhcp_lan server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", auto_config: false, adapter: 3
    node.vm.provision "shell", path: "provision/client1.sh"
  end

  # Client 2
  config.vm.define "client2" do |node|
    node.vm.hostname = "client2"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "client2"
      vb.memory = 512
      vb.cpus = 1
    end

    # Configure the private network with DHCP-assigned IP address from mgmt server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet4", auto_config: false, adapter: 2
    # Configure the private network with DHCP-assigned IP address from dns_dhcp_lan server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", auto_config: false, adapter: 3
    node.vm.provision "shell", path: "provision/client2.sh"
  end

  ######################
  # Database Server
  ######################
  config.vm.define "database" do |node|
    node.vm.hostname = "database"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "database"
      vb.memory = 2048
      vb.cpus = 1
    end

    # Add four 20GB disks for RAID 5
    node.vm.disk :disk, size: "20GB", name: "database-disk0.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk1.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk2.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk3.vdi", primary: false

    # Private network with static IP 192.168.4.50
    node.vm.network :private_network, ip: "192.168.4.50", auto_config: false, virtualbox__intnet: "inet4", adapter: 2
    # Private network with static IP 192.168.5.50
    node.vm.network :private_network, ip: "192.168.5.50", auto_config: false, virtualbox__intnet: "inet5", adapter: 3

    # Provisioning script for RAID 5 setup
    node.vm.provision "shell", path: "provision/software-raid/setup-raid5.sh"
    node.vm.provision "shell", path: "provision/database.sh"
    node.vm.provision "shell", path: "provision/mysql-setup.sh"
  end

  ######################
  # Web Server
  ######################
  config.vm.define "webserver" do |node|
    node.vm.hostname = "webserver"
    node.vm.box = "ubuntu/focal64"
    node.vm.provider :virtualbox do |vb|
      vb.name = "webserver"
      vb.memory = 1024
      vb.cpus = 1
    end
    
    # Configure the private network with static IP address
    node.vm.network :private_network, ip: "192.168.4.30", virtualbox__intnet: "inet4", auto_config: false, adapter: 2
    # Configure to have assigned with DHCP in 192.168.5.X network
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", auto_config: false, adapter: 3
    node.vm.provision "shell", path: "provision/web-server.sh"
    node.vm.provision "shell", path: "provision/webserver-contents/install-node-prisma.sh"
    node.vm.provision "shell", path: "provision/webserver-contents/setup-prisma-app.sh"
  end
end