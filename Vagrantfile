Vagrant.configure("2") do |config|

  # Read the host's standard id_rsa public key and inject it into VMs during provisioning
  # so `ssh vagrant@192.168.56.10` works without a password (no -i flag needed).
  # If ~/.ssh/id_rsa does not exist yet, run `ssh-keygen -t rsa` on your host first.
  HOST_PUB_KEY_PATH = File.expand_path("~/.ssh/id_rsa.pub")
  HOST_PUB_KEY = File.exist?(HOST_PUB_KEY_PATH) ? File.read(HOST_PUB_KEY_PATH).strip : nil
  puts "==> [host-pubkey] WARNING: ~/.ssh/id_rsa.pub not found — passwordless SSH will not be set up. Run: ssh-keygen -t rsa" unless HOST_PUB_KEY

  # Box used by all VMs
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202510.26.0"

  # Disable shared vagrant folders
  config.vm.synced_folder ".", "/vagrant", disabled: true

  ######################
  # Management Server
  ######################
  config.vm.define "mgmt" do |node|
    node.vm.hostname = "mgmt"
    node.vm.provider :virtualbox do |vb|
      vb.name = "mgmt"
      vb.memory = 2048
      vb.cpus = 2
    end
    # use the static IP address for the host-only network
    node.vm.network :private_network, ip: "192.168.56.10", adapter: 2
    # Internal network (inet5) for DHCP clients, mgmt server will be the DHCP server
    node.vm.network :private_network, ip: "192.168.5.10", auto_config: false, virtualbox__intnet: "inet5", adapter: 3
    node.vm.provision "shell", path: "provision/mgmt.sh"
    # Install Ansible and scaffold on mgmt VM after networking is configured
    node.vm.provision "shell", path: "provision/setup-ansible.sh"
    # Inject the Windows host's public key so VS Code Remote SSH connects without a password
    if HOST_PUB_KEY
      node.vm.provision "shell", name: "inject-host-pubkey", inline: <<-SHELL
        KEY='#{HOST_PUB_KEY}'
        mkdir -p /home/vagrant/.ssh
        if ! grep -qF "$KEY" /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
          echo "$KEY" >> /home/vagrant/.ssh/authorized_keys
          echo "[host-pubkey] Injected host public key into authorized_keys"
        else
          echo "[host-pubkey] Host public key already present — skipping"
        fi
        chmod 700 /home/vagrant/.ssh
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
    end
  end

  ########################################
  # DNS DHCP Host for the hostonly network
  # Provisioned after mgmt so it can fetch mgmt's public key on first vagrant up
  ########################################
  config.vm.define "dns_dhcp_host" do |node|
    node.vm.hostname = "dns-dhcp-host"
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
  # Router
  ######################
  config.vm.define "router" do |node|
    node.vm.hostname = "router"
    node.vm.provider :virtualbox do |vb|
      vb.name = "router"
      vb.memory = 512
      vb.cpus = 1
    end
    # Internal network (inet4), have a static IP address for the router
    node.vm.network :private_network, ip: "192.168.4.1", auto_config: false, virtualbox__intnet: "inet4", adapter: 2
    # Internal network (inet5), static gateway IP — the router IS the gateway for 192.168.5.0/24
    node.vm.network :private_network, ip: "192.168.5.1", auto_config: false, virtualbox__intnet: "inet5", adapter: 3
    # bridge network to host Wi-Fi network which is used for the router to connect to the internet
    node.vm.network :public_network, bridge: "Intel(R) Wi-Fi 6 AX200 160MHz", auto_config: false, adapter: 4
    node.vm.provision "shell", path: "provision/router.sh"
  end

  ##################
  # DNS DHCP LAN
  ##################
  config.vm.define "dns_dhcp_lan" do |node|
    node.vm.hostname = "dns-dhcp-lan"
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
    node.vm.provider :virtualbox do |vb|
      vb.name = "client1"
      vb.memory = 1024
      vb.cpus = 1
    end

    # Configure the private network with DHCP-assigned IP address from mgmt server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet4", auto_config: false, adapter: 2
    # Configure the private network with DHCP-assigned IP address from dns_dhcp_lan server
    node.vm.network :private_network, type: "dhcp", virtualbox__intnet: "inet5", auto_config: false, adapter: 3
    node.vm.provision "shell", path: "provision/client1.sh"

    node.vm.network "forwarded_port", guest: 3000, host: 3000   # Grafana (in order to access from my personal host)
    node.vm.network "forwarded_port", guest: 9090, host: 9090   # Prometheus (in order to access from my personal host)
  end

  ###################
  # Client 2
  ###################
  config.vm.define "client2" do |node|
    node.vm.hostname = "client2"
    node.vm.provider :virtualbox do |vb|
      vb.name = "client2"
      vb.memory = 1024
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
    node.vm.provider :virtualbox do |vb|
      vb.name = "database"
      vb.memory = 1024
      vb.cpus = 1
    end

    ########
    # RAID 5
    ########
    # Four 20GB disks for RAID 5 (requires Vagrant 2.2.8+; set VAGRANT_EXPERIMENTAL="disks" if on older versions)
    # These become /dev/sdb, /dev/sdc, /dev/sdd, /dev/sde inside the VM (sda is the primary boot disk)
    node.vm.disk :disk, size: "20GB", name: "database-disk0.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk1.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk2.vdi", primary: false
    node.vm.disk :disk, size: "20GB", name: "database-disk3.vdi", primary: false

    # Private network with static IP 192.168.4.50
    node.vm.network :private_network, ip: "192.168.4.50", auto_config: false, virtualbox__intnet: "inet4", adapter: 2
    # Private network with static IP 192.168.5.50
    node.vm.network :private_network, ip: "192.168.5.50", auto_config: false, virtualbox__intnet: "inet5", adapter: 3

    # RAID configuration are still work in progress as of now 
    node.vm.provision "shell", path: "provision/database.sh"
    #node.vm.provision "shell", path: "provision/mysql-setup.sh"
    #node.vm.provision "shell", path: "provision/software-raid/setup-raid5.sh"
  end
end