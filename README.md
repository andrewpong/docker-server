After fresh Ubuntu Server 16.04 install, run the following command:

```
git clone https://github.com/aberg83/docker-server.git && cd ~/docker-server && sudo ./docker-server.sh
```

System will reboot when script finishes. Make note of the CrashPlan .ui_info content at the end of the script execution. If you miss it before reboot, you can run:

```
cat "/path/to/config"/crashplan/id/.ui_info
```

Upon reboot, you will be able to access the apps at "yourdomain.com"/"appname". Your browser will prompt you for the login credentials you set within the script.

Note that as of now, PlexRequests.NET requires that Nginx be shut down and the base URL be manually set for reverse proxying. Run the following:

```
sudo systemctl stop nginx
```
Next, visit "yourdomain.com":3579, change the base URL setting to '/request' and hit save. Now, start Nginx:

```
sudo systemctl start nginx
```

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
- aptalca/nginx-letsencrypt
- jrcs/crashplan
