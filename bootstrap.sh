#!/bin/sh

# This script bootstraps the system by installing Git, Ansible, and related tools.
#
# Note:
# The version of Ansible in the system's default repositories may be outdated.
# To ensure the latest version, this script uses `pipx` to install Ansible.
# Once installed, the script runs the main configuration using `ansible-pull`.
#
# Usage:
#   Run this script with administrator privileges:
#     $ sudo sh /path/to/bootstrap.sh
#
# Development:
#   To use a specific branch of the playbook repository, set the `ANSIBLE_BRANCH` environment variable.
#   If not specified, the script defaults to the `main` branch.

set -e

# Check if the host is running the systemd init system.
if [ -d "/run/systemd/system" ]
then
    alias log='logger -s -t bootstrap.sh'
else
    alias log='echo'
fi

export DEBIAN_FRONTEND=noninteractive

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
apt-get install -y sudo git dirmngr pipx python3-pip
log "Installed bootstrap packages."

# Install Ansible via pipx.
# Note that pipx from Debian repo doesn't have --global option of ensurepath subcommand.
# Manually supply installation options.
PIPX_HOME=/opt/pipx \
PIPX_BIN_DIR=/usr/local/bin \
PIPX_MAN_DIR=/usr/local/share/man \
pipx install --force --include-deps ansible
log "Installed $(ansible --version)"

# Invoke `ansible-pull` twice: once as root for system-level setup, and once as
# the unprivileged user for user-level configuration.
ansible-pull -v \
    --url ${MAIN_PLAYBOOK_REPO} \
    --checkout ${MAIN_PLAYBOOK_BRANCH} \
    --inventory hosts \
    --limit system \
    install_requirements.yml ${MAIN_PLAYBOOK}

sudo -E -H -u ${USER_NAME:-guest} \
    ansible-pull -v \
    --url ${MAIN_PLAYBOOK_REPO} \
    --checkout ${MAIN_PLAYBOOK_BRANCH} \
    --inventory hosts \
    --limit user \
    install_requirements.yml ${MAIN_PLAYBOOK}

log "Ansible completed the main playbook."
