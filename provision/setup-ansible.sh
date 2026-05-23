#!/bin/bash
set -e

echo "==> Installing Ansible and prerequisites"
export DEBIAN_FRONTEND=noninteractive

apt-get update

# Ansible is available in Ubuntu 20.04 default repos — no PPA needed
apt-get install -y ansible sshpass

ANSIBLE_DIR=/home/vagrant/ansible
echo "==> Creating Ansible scaffold at $ANSIBLE_DIR"
mkdir -p "$ANSIBLE_DIR"/inventory
mkdir -p "$ANSIBLE_DIR"/group_vars
mkdir -p "$ANSIBLE_DIR"/playbooks/deploy/files
mkdir -p "$ANSIBLE_DIR"/roles/public_key/tasks

chown -R vagrant:vagrant "$ANSIBLE_DIR"

cat > "$ANSIBLE_DIR"/inventory/hosts <<'EOF'
[mgmt]
192.168.5.10 ansible_connection=local

[lab]
# Add your lab hosts here (examples):
192.168.5.50
192.168.4.50
EOF

cat > "$ANSIBLE_DIR"/group_vars/all.yml <<'EOF'
---
# Shared variables for all hosts
ansible_user: vagrant
EOF

cat > "$ANSIBLE_DIR"/site.yml <<'EOF'
- import_playbook: playbooks/deploy/deploy.yml
EOF

cat > "$ANSIBLE_DIR"/playbooks/deploy/deploy.yml <<'EOF'
---
- name: Deploy sample files to lab hosts
  hosts: lab
  become: yes
  vars_files:
    - ../../group_vars/all.yml
  tasks:
    - name: Ensure /tmp/deploy exists
      file:
        path: /tmp/deploy
        state: directory
        owner: "{{ ansible_user }}"
        mode: '0755'

    - name: Copy sample file
      copy:
        src: files/hello.txt
        dest: /tmp/deploy/hello.txt
        owner: "{{ ansible_user }}"
        mode: '0644'
EOF

cat > "$ANSIBLE_DIR"/playbooks/deploy/files/hello.txt <<'EOF'
Hello from Ansible deploy!
EOF

cat > "$ANSIBLE_DIR"/roles/public_key/tasks/main.yml <<'EOF'
---
# public_key role placeholder
- debug:
    msg: "public_key role placeholder - add tasks to deploy SSH public keys"
EOF

chown -R vagrant:vagrant "$ANSIBLE_DIR"
chmod -R 0755 "$ANSIBLE_DIR"

# Write ansible.cfg to ~/  so Ansible picks it up automatically when run from home directory
cat > /home/vagrant/ansible.cfg <<'EOF'
[defaults]
roles_path = ./ansible/roles
inventory = ./ansible/inventory/hosts

[privilege_escalation]
become = True
EOF
chown vagrant:vagrant /home/vagrant/ansible.cfg
chmod 644 /home/vagrant/ansible.cfg

echo "==> Ansible scaffold created at $ANSIBLE_DIR"
echo "To run: vagrant ssh mgmt && sudo -u vagrant ansible-playbook -i /home/vagrant/ansible/inventory/hosts /home/vagrant/ansible/site.yml"

exit 0
