Vagrant.configure("2") do |config|
  require_relative "vagrant_config_data"

  VM_CONFIG.each do |vm|
    config.vm.define vm[:name] do |node|
      node.vm.hostname = vm[:hostname]
      node.vm.box = "ubuntu/focal64"

      node.vm.provider :virtualbox do |vb|
        vb.name = vm[:name]
        vb.memory = vm[:memory]
        vb.cpus = vm[:cpus]
      end

      # Prevent default NAT SSH port forwarding
      if vm[:forwarded_ports]&.empty?
        node.vm.network "forwarded_port", guest: 22, host: nil
      end

      vm[:networks].each do |net|
        # Build network options
        options = { adapter: net[:nic] }
        options[:virtualbox__intnet] = net[:virtualbox__intnet] if net[:virtualbox__intnet]
        options[:auto_config] = net[:auto_config] if net.key?(:auto_config)

        case net[:nwtype]
        when "private_network"
          if net[:ip]
            node.vm.network :private_network, ip: net[:ip], **options
          else
            node.vm.network :private_network, type: "dhcp", **options
          end
        when "public_network"
          node.vm.network :public_network, type: "dhcp", **options
        end
      end

      node.vm.provision "shell", path: vm[:provision]
    end
  end
end
