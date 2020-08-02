#!/bin/sh

# As an initial step, install git, ansible and friends. A Debian-based system
# has tasksel, a built-in package management tool. Define a custom task and
# install those multiple packages at once. Subsequently proceed to the main
# playbook with ansible-pull. This script must be run with an administrator
# privilege and its usage is simply "$ sudo sh /path/to/bootstrap.sh".

# TODO: Sometimes ansible from the main archive is too old. Add a bootstrap
# playbook that makes system's conservative ansible upgrade itself to the latest
# version.

set -e
alias log='logger -s -t $(basename $0)'

DESCS_DIR="/usr/share/tasksel/descs"
BOOT_TASK="${DESCS_DIR}/bootstrap.desc"
MAIN_PLAYBOOK="main.yml"
MAIN_PLAYBOOK_REPO="https://github.com/keisrk/morning_routine"

log "Started bootstrap script."

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
 ansible
Section: user
EOF

log "Created ${BOOT_TASK}."

tasksel install bootstrap
log "Tasksel completed bootstrap task."

ansible-pull --url ${MAIN_PLAYBOOK_REPO} ${MAIN_PLAYBOOK}
log "Ansible completed the main playbook."
