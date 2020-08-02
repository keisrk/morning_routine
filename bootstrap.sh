#!/bin/sh

# As an initial step, install git, ansible and friends. A Debian-based system
# has tasksel, a built-in package management tool. Define a custom task and
# install those multiple packages at once. Sometimes ansible from the main
# archive is too old. A bootstrap playbook makes the system's conservative
# ansible upgrade itself to the latest version. Subsequently proceed to the main
# playbook with ansible-pull. This script must be run with an administrator
# privilege and its usage is simply "$ sudo sh /path/to/bootstrap.sh".


set -e
alias log='logger -s -t bootstrap.sh'

DESCS_DIR="/usr/share/tasksel/descs"
BOOT_TASK="${DESCS_DIR}/bootstrap.desc"
ANSIBLE_VERSION="2.9"
BOOT_PLAYBOOK="$(mktemp -t bootstrap_XXXXXXXXXX.yml)"
MAIN_PLAYBOOK="main.yml"
MAIN_PLAYBOOK_REPO="https://github.com/keisrk/morning_routine"

log "Started bootstrap script."

# Perform system update
apt-get update -y
apt-get upgrade -y
log "Made system up-to-date."

# Check if tasksel is present in the system.
if [ ! -x "$(command -v tasksel)" ]
then
    log "tasksel not found. Installing..."
    apt-get install tasksel -y
fi

# Check write permission.
if [ ! -w ${DESCS_DIR} ]
then
    log "${DESCS_DIR} doesn't exist or not writable. Exiting..."
    exit 1
fi

cat <<EOF > ${BOOT_TASK}
Task: bootstrap
Relevance: 9
Description: Bootstrap
 Install git, ansible and relevant utilities.
Key:
Packages: list
 git
 dirmngr
 ansible
Section: user
EOF

log "Created ${BOOT_TASK}."

tasksel install bootstrap
log "Tasksel completed bootstrap task."

cat <<EOF > ${BOOT_PLAYBOOK}
---
- hosts: localhost

  tasks:

  - name: add an apt key by id from a keyserver
    apt_key:
      keyserver: keyserver.ubuntu.com
      id: 93C4A3FD7BB9C367

  - name: add upstream repository of the latest ansible
    apt_repository:
      filename: ansible
      repo: deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main

  - name: ensure ansible is up to date
    apt:
      name: ansible
      update_cache: yes
      state: latest
EOF

log "Created ${BOOT_PLAYBOOK}."

# Check ansible's version.
if ! ansible --version | head -n 1 | grep -q ${ANSIBLE_VERSION}
then
    log "System's ansible is obsolete. Installing from upstream..."
    ansible-playbook ${BOOT_PLAYBOOK}
    log "Installed $(ansible --version | head -n 1)"
else
    log "Matched to the right version of ansible. Proceeding..."
fi

ansible-pull --url ${MAIN_PLAYBOOK_REPO} ${MAIN_PLAYBOOK}
log "Ansible completed the main playbook."
