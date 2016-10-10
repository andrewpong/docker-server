After fresh Ubuntu Server 16.04 install, complete the following:

1. Run 'sudo passwd root' to set a root password.
2. Type 'git clone https://github.com/aberg83/BergPlex.git BergPlex'.
3. Run 'su root'. Enter root password previously set.
4. Move to scripts folder 'cd ~/BergPlex/scripts/'.
5. Run './setup.sh'.

The above assumes that you already have a master user with sudo priveleges. This is the user you should select when running the script. Make note of the CrashPlan settings. System will reboot when script finishes.

Enjoy!
