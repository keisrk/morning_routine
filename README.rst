===============
Morning Routine
===============

Ansible playbook that gets your ducks in a row over a cup of coffee.

Usage
=====

When you create an AWS Lightsail instance, cut & paste following lines to the
"Launch script" field. It may take a while until Ansible completes its tasks. To
monitor the progress, ``$ tail -f /var/log/cloud-init-output.log``.

As part of the setup, Ansible creates a fresh unprivileged user with no login
password. It also installs the `OPKSSH`_ extension to enable authentication via
Google SSO. For detailed usage and configuration, refer to the `OPKSSH`_
documentation.


.. code:: bash

   export USER_NAME=guest
   export USER_GECOS="Guest Account"
   export USER_EMAIL=guest@morningrouti.ne
   curl -sL https://raw.githubusercontent.com/keisrk/morning_routine/main/bootstrap.sh | sh


.. _OPKSSH: https://github.com/openpubkey/opkssh/
