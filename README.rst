===============
Morning Routine
===============

Ansible playbook that gets your ducks in a row over a cup of coffee.

Usage
=====

When you create an AWS Lightsail instance, cut & paste following lines to the
"Launch script" field. It may take a while until Ansible completes its tasks. To
monitor the progress, ``$ tail -f /var/log/cloud-init-output.log``. Ansible also
creates a fresh disabled user with no login password. To enable it, ``$ sudo
passwd <USER_NAME>`` and enter a new password for the user.

.. code:: bash

   export USER_NAME=guest
   export USER_GECOS="Guest Account"
   export USER_EMAIL=guest@morningrouti.ne
   curl -sL https://raw.githubusercontent.com/keisrk/morning_routine/main/bootstrap.sh | sh
