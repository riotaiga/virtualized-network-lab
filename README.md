# virtualized-network-lab

A multi-VM home lab built with Vagrant and VirtualBox running Ubuntu 24.04. It simulates a small routed network with a management server, DNS/DHCP servers, a router, clients, and a database — all provisioned automatically on `vagrant up`.

---

## Prerequisites

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- The `bento/ubuntu-24.04` box (`202510.26.0`) — downloaded automatically on first `vagrant up`

---

## Network Topology

```
Host machine
│
├─ 192.168.56.0/24  (host-only — accessible from your machine)
│   ├─ mgmt          192.168.56.10
│   └─ dns_dhcp_host 192.168.56.20
│
├─ 192.168.5.0/24   (inet5 — internal management network)
│   ├─ mgmt          192.168.5.10   ← DHCP server for this subnet
│   ├─ router        192.168.5.1    ← gateway
│   ├─ dns_dhcp_lan  DHCP-assigned
│   ├─ client1       DHCP-assigned
│   ├─ client2       DHCP-assigned
│   └─ database      192.168.5.50
│
└─ 192.168.4.0/24   (inet4 — internal LAN network)
    ├─ router        192.168.4.1    ← gateway
    ├─ dns_dhcp_lan  192.168.4.20   ← DHCP server for this subnet
    ├─ client1       DHCP-assigned
    ├─ client2       DHCP-assigned
    └─ database      192.168.4.50
```

---

## VMs

| VM             | Hostname       | Role                                              | Memory  | CPUs |
|----------------|----------------|---------------------------------------------------|---------|------|
| `mgmt`         | mgmt           | Management server, DHCP for inet5, Ansible        | 2048 MB | 2    |
| `dns_dhcp_host`| dns-dhcp-host  | DNS/DHCP for the host-only (192.168.56.0/24) network | 512 MB | 1 |
| `router`       | router         | Gateway/NAT for inet4 and inet5, internet via bridged Wi-Fi | 512 MB | 1 |
| `dns_dhcp_lan` | dns-dhcp-lan   | DNS/DHCP for the LAN (192.168.4.0/24) network    | 1024 MB | 1    |
| `client1`      | client1        | DHCP client on both internal networks             | 1024 MB | 1    |
| `client2`      | client2        | DHCP client on both internal networks             | 1024 MB | 1    |
| `database`     | database       | MySQL database server                             | 1024 MB | 1    |

Provision order: `mgmt` → `dns_dhcp_host` → `router` → `dns_dhcp_lan` → `client1` → `client2` → `database`

---

## Getting Started

```bash
vagrant up
```

To bring up a single VM:

```bash
vagrant up mgmt
```

To re-run provisioning on a running VM:

```bash
vagrant provision mgmt
```

To destroy and rebuild everything:

```bash
vagrant destroy -f && vagrant up
```

---

## Accessing the Lab

### Passwordless SSH setup (automatic)

On `vagrant up`, the Vagrantfile reads your host's existing public key at `~/.ssh/id_rsa.pub` and injects it into `mgmt`'s `authorized_keys` during provisioning.

> If `~/.ssh/id_rsa.pub` does not exist yet, run `ssh-keygen -t rsa` on your host first. Without it, passwordless SSH will not be set up and a warning will be printed during `vagrant up`.

This means you can SSH into `mgmt` from your host without ever typing a password:

```bash
ssh vagrant@192.168.56.10
```

For VS Code Remote SSH, add this to your `~/.ssh/config`:

```
Host lab-mgmt
    HostName 192.168.56.10
    User vagrant
    IdentityFile ~/.ssh/id_rsa
```

Then connect via VS Code's Remote Explorer to `lab-mgmt` — no password prompt.

---

### mgmt and dns_dhcp_host (directly reachable from your host)

`mgmt` and `dns_dhcp_host` are on the **host-only** network (`192.168.56.0/24`), reachable directly from your Windows host (`192.168.56.1`):

```bash
ssh vagrant@192.168.56.10   # mgmt
ssh vagrant@192.168.56.20   # dns_dhcp_host

# Or via Vagrant (always works)
vagrant ssh mgmt
vagrant ssh dns_dhcp_host
```

### client1, client2, router, dns_dhcp_lan, database (internal networks only)

`inet4` and `inet5` are VirtualBox **internal networks** — your host has no interface on them. Two options:

**Option A — `vagrant ssh` (simplest)**

```bash
vagrant ssh client1
vagrant ssh client2
vagrant ssh router
vagrant ssh dns_dhcp_lan
vagrant ssh database
```

**Option B — SSH jump through mgmt**

Use `mgmt` as a jump host to reach any internal VM directly (Ex. using vscode):

```bash
ssh -J vagrant@192.168.56.10 vagrant@<ip>
```

For convenience, add entries to `~/.ssh/config`:

```
Host lab-client1
    HostName 192.168.5.127        # replace with actual DHCP lease
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ProxyJump lab-mgmt
```

> **Finding DHCP leases:** `vagrant ssh mgmt` then run `cat /var/lib/misc/dnsmasq.leases`

From `mgmt`, passwordless SSH to all other VMs is set up automatically during provisioning using an RSA key generated on `mgmt` and pushed to each VM's `authorized_keys`.

---

## Provision Scripts

| Script                    | Purpose                                                        |
|---------------------------|----------------------------------------------------------------|
| `provision/mgmt.sh`       | Netplan, dnsmasq DHCP for inet5, SSH keypair generation        |
| `provision/setup-ansible.sh` | Installs Ansible, creates scaffold at `/home/vagrant/ansible` |
| `provision/dns_dhcp_host.sh` | Netplan, dnsmasq for host-only network, fetches mgmt SSH key |
| `provision/router.sh`     | Netplan, IP forwarding, iptables NAT via bridged adapter       |
| `provision/dns_dhcp_lan.sh` | Netplan, dnsmasq DHCP for inet4, fetches mgmt SSH key        |
| `provision/client1.sh`    | Netplan (DHCP on both interfaces), fetches mgmt SSH key        |
| `provision/client2.sh`    | Netplan (DHCP on both interfaces), fetches mgmt SSH key        |
| `provision/database.sh`   | Netplan static IPs, fetches mgmt SSH key                       |
| `provision/mysql-setup.sh`| MySQL root password, testdb, external access                   |

All scripts wipe `/etc/netplan/*.yaml` before writing their own config to avoid conflicts with Vagrant's auto-generated `50-vagrant.yaml`. Every netplan config explicitly includes `enp0s3` (the VirtualBox NAT adapter) with `dhcp4: true` so `vagrant ssh` and `apt-get` continue to work.

---

## Ansible (Still in Progress)

An Ansible scaffold is installed on `mgmt` at `/home/vagrant/ansible`:

```
/home/vagrant/ansible/
├── inventory/
│   └── hosts          # mgmt (local) + lab hosts (database, etc.)
├── group_vars/
│   └── all.yml        # shared variables (ansible_user: vagrant)
├── playbooks/
│   └── deploy/
│       ├── deploy.yml # copies files to lab hosts
│       └── files/     # files to deploy
├── roles/
│   └── public_key/
│       └── tasks/
│           └── main.yml
└── site.yml           # top-level playbook
```

To run a playbook from `mgmt`:

```bash
vagrant ssh mgmt
cd ~/ansible
ansible-playbook -i inventory/hosts site.yml
```

---

## Repository Structure

```
Vagrantfile              # defines all VMs
provision/
  mgmt.sh
  setup-ansible.sh
  dns_dhcp_host.sh
  dns_dhcp_lan.sh
  router.sh
  client1.sh
  client2.sh
  database.sh
  mysql-setup.sh
  software-raid/         # RAID setup scripts (reference)
  webserver-contents/    # web server install scripts (reference)
  ansible/               # Ansible playbooks directory
ssh_keys/                # public SSH keys for mgmt server
Network-Diagram.drawio   # network diagram (open with draw.io)
```

> `redhat-test/`, `test1/`, `test2/`, `test3/`, `test100/` are archived iterations kept for reference — the active lab is the root `Vagrantfile` and `provision/` directory.
