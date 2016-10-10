Docker-Server

After fresh Ubuntu Server 16.04 install, complete the following:

1. Run 'sudo passwd root' to set a root password.
2. Type 'git clone https://github.com/aberg83/docker-server.git docker-server'.
3. Move to scripts folder 'cd ~/docker-server/scripts/'.
4. Run 'su root'. Enter root password previously set. 
5. Run './docker-server.sh'.

The above assumes that you are initially logged in as a master user with sudo priveleges. This is the user you should select when running the script. System will reboot when script finishes. Make note of the CrashPlan .ui_info content at the end of the script execution. If you miss it before reboot, you can run 'cat "/path/to/config"/crashplan/id/.ui_info'.

Upon reboot, you will be able to access the apps at "yourdomain.com"/"appname". Your browser will prompt you for the login credentials you set within the script.

Enjoy!

Installed docker containers:
- linuxserver/plex
- linuxserver/couchpotato
- linuxserver/sonarr
- linuxserver/plexpy
- linuxserver/plexrequests
- linuxserver/nginx
- linuxserver/jackett
- linuxserver/sabnzbd
- linuxserver/deluge
- jrcs/crashplan

Known issues:
- Sometimes docker install will fail. If it does, run the script again.
