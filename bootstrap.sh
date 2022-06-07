#!/bin/sh

# As an initial step, install git, ansible and friends. Sometimes ansible from
# the main archive is too old. A bootstrap playbook makes the system's
# conservative ansible upgrade itself to the latest version. Subsequently
# proceed to the main playbook with ansible-pull. This script must be run with
# an administrator privilege and its usage is simply "$ sudo sh
# /path/to/bootstrap.sh".

# For development, specify a branch to checkout by setting ANSIBLE_BRANCH. By
# default it checks out main branch.

set -e

# Check if the host is running the systemd init system.
if [ -d "/run/systemd/system" ]
then
    alias log='logger -s -t bootstrap.sh'
else
    alias log='echo'
fi

export DEBIAN_FRONTEND=noninteractive

LATEST_ANSIBLE_VERSION="5.9" # Latest version shown in the Ansible documentation.
BOOT_PLAYBOOK="$(mktemp -t bootstrap_XXXXXXXXXX.yml)"
MAIN_PLAYBOOK=${ANSIBLE_MAIN:-main.yml}
MAIN_PLAYBOOK_REPO="https://github.com/keisrk/morning_routine"
MAIN_PLAYBOOK_BRANCH=${ANSIBLE_BRANCH:-main}
# Fix the ansible working directory
ANSIBLE_LOCAL_TEMP=/tmp/.ansible/tmp
ANSIBLE_REMOTE_TEMP=/tmp/.ansible/tmp

log "Started bootstrap script."

# Perform system update
apt-get update -y
apt-get upgrade -y
log "Made system up-to-date."

# Install bootstrap packages.
apt-get install -y sudo git dirmngr ansible python3-pip
log "Installed bootstrap packages."

cat <<EOF > ${BOOT_PLAYBOOK}
---
- hosts: localhost

  tasks:

  - name: Add upstream repository of the latest ansible to Ubuntu
    apt_repository:
      filename: ansible
      repo: ppa:ansible/ansible
    when: ansible_distribution == 'Ubuntu'

  - name: Add upstream repository of the latest ansible to Debian
    block:
      - name: Add an apt key by id from a keyserver
        apt_key:
          keyserver: keyserver.ubuntu.com
          id: 93C4A3FD7BB9C367

      - name: Use matching ubuntu release
        apt_repository:
          filename: ansible
          repo: "deb http://ppa.launchpad.net/ansible/ansible/ubuntu\
            {{ releases[ansible_distribution_release] }} main"
        vars:
          releases:
            bullseye: focal
            buster: bionic
            stretch: xenial
            jessie: trusty

    when: ansible_distribution == 'Debian'

  - name: Ensure ansible is up to date
    apt:
      name: ansible
      update_cache: yes
      state: latest
EOF

log "Created ${BOOT_PLAYBOOK}."

# Obtain system's ansible version.
SYSTEM_ANSIBLE_VERSION="$(dpkg-query --show --showformat '${Version}' ansible)"

# Check if the version is the latest one.
if dpkg --compare-versions ${SYSTEM_ANSIBLE_VERSION} lt ${LATEST_ANSIBLE_VERSION}
then
    log "System's ansible is obsolete. Installing from upstream..."
    ansible-playbook ${BOOT_PLAYBOOK}
    log "Installed $(ansible --version | head -n 1)"
else
    log "Matched to the right version of ansible. Proceeding..."
fi

ansible-pull -v \
    --url ${MAIN_PLAYBOOK_REPO} \
    --checkout ${MAIN_PLAYBOOK_BRANCH} \
    --inventory hosts \
    --limit system \
    ${MAIN_PLAYBOOK}

sudo -E -H -u ${USER_NAME:-guest} \
    ansible-pull -v \
    --url ${MAIN_PLAYBOOK_REPO} \
    --checkout ${MAIN_PLAYBOOK_BRANCH} \
    --inventory hosts \
    --limit user \
    ${MAIN_PLAYBOOK}

log "Ansible completed the main playbook."
