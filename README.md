BergPlex Script

After fresh Ubuntu Server 16.04 install, complete the following:

1. As root, run 'adduser aberg'.
2. As root, run 'adduser aberg sudo'.
3. Type 'su aberg'.
4. Type 'cd ~'.
5. Type 'git clone https://github.com/aberg83/BergPlex.git BergPlex'. Enter credentials.
5. Move to scripts folder 'cd ~/BergPlex/scripts/'.
6. Execute docker install by running 'sudo ./docker.sh'. Enter password.
7. After system reboot, complete installation by running 'sudo ./containers.sh'. Enter password.
8. Restore from CrashPlan backup with containers stopped if this is a rebuild.
9. Enjoy.
