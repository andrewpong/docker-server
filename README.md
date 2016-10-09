BergPlex Script

After fresh Ubuntu Server 16.04 install, complete the following:

1. As root, run 'adduser aberg'.
2. As root, run 'adduser aberg sudo'.
3. SFTP into server using 'aberg' account.
4. Upload 'BergPlex' script folder to 'aberg' home directory.
5. Move to scripts folder 'cd ~/BergPlex/scripts/'.
5. Make scripts executable by running 'chmod a+x *'.
6. Execute docker install by running 'sudo ./docker.sh'.
7. After system reboot, complete installation by running 'sudo ./containers.sh'.