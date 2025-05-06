VM_CONFIG = [
  {
    name: "dns_dhcp_host",
    hostname: "dns-dhcp-host",
    memory: 512,
    cpus: 1,
    networks: [
      { nwtype: "public_network", type: "dhcp", nic: 2 }  # enp0s8
    ],
    provision: "provision/dns_dhcp_host.sh"
  },
  {
    name: "mgmt",
    hostname: "mgmt",
    memory: 1024,
    cpus: 1,
    networks: [
      { nwtype: "public_network", type: "dhcp", auto_config: false, nic: 2 },           # enp0s8
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
      { nwtype: "public_network", type: "dhcp", nic: 4 }                    # enp0s10
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