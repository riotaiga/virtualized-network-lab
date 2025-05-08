VM_CONFIG = [
  {
    name: "dns_dhcp_host",
    hostname: "dns-dhcp-host",
    memory: 512,
    cpus: 1,
    networks: [
      { nwtype: "private_network", ip: "192.168.56.20", nic: 2 }  # enp0s8 Host-only network  (it was public_network before)
      # if more VM needs to be created on the host network using netplan and dnsmasq to operate as a dns/dhcp server, then add the following line:
      # { nwtype: "private_network", ip: " 
    ],
    provision: "provision/dns_dhcp_host.sh"
  },
  {
    name: "mgmt",
    hostname: "mgmt",
    memory: 1024,
    cpus: 1,
    networks: [
      { nwtype: "private_network", ip: "192.168.56.10", nic: 2 },           # enp0s8 Host-only network  (it was public_network before)
      { nwtype: "private_network", ip: "192.168.5.10", auto_config: false,
        virtualbox__intnet: "inet5", nic: 3 }                                           # enp0s9
    ],
    provision: "provision/mgmt.sh"
  },
  {
    name: "router",
    hostname: "router",
    memory: 512,
    cpus: 1,
    networks: [
      { nwtype: "private_network", ip: "192.168.4.1", auto_config: false,
        virtualbox__intnet: "inet4", nic: 2 },  # enp0s8
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet5", nic: 3 },          # enp0s9
      { nwtype: "public_network", bridge: "Intel(R) Wi-Fi 6 AX200 160MHz", auto_config: true, nic: 4 }  # bridged network-enp0s10
    ],
    provision: "provision/router.sh"
  },
  {
    name: "dns_dhcp_lan",
    hostname: "dns-dhcp-lan",
    memory: 1024,
    cpus: 1,
    networks: [
      { nwtype: "private_network", ip: "192.168.4.20", auto_config: false,
        virtualbox__intnet: "inet4", nic: 2 },         # enp0s8
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet5", nic: 3 }          # enp0s9
    ],
    provision: "provision/dns_dhcp_lan.sh"
  },
  {
    name: "client1",
    hostname: "client1",
    memory: 512,
    cpus: 1,
    networks: [
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet4", auto_config: false, nic: 2 },  # enp0s8
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet5", auto_config: false, nic: 3 }   # enp0s9
    ],
    provision: "provision/client1.sh"
  },
  {
    name: "client2",
    hostname: "client2",
    memory: 512,
    cpus: 1,
    networks: [
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet4", auto_config: false, nic: 2 },  # enp0s8
      { nwtype: "private_network", type: "dhcp",
        virtualbox__intnet: "inet5", auto_config: false, nic: 3 }   # enp0s9
    ],
    provision: "provision/client2.sh"
  }
]