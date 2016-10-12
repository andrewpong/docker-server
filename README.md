After a fresh Ubuntu Server 16.04 install, run the following command:

```
git clone https://github.com/aberg83/docker-server.git && cd ~/docker-server && sudo ./docker-server.sh
```

System will reboot when script finishes. Upon reboot, you will be able to access the apps at appname.yourdomain.com. Your browser will prompt you for the login credentials you set within the script.

Enjoy!

Installed docker containers:
- linuxserver/plex
- linuxserver/couchpotato
- linuxserver/sonarr
- linuxserver/plexpy
- linuxserver/jackett
- linuxserver/sabnzbd
- linuxserver/deluge
- rogueosb/plexrequestsnet
- jwilder/nginx-proxy
- jrcs/letsencrypt-nginx-proxy-companion
- jrcs/crashplan
