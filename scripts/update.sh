#!/bin/bash

# Variables

        CONFIG=/opt/docker
        MEDIA=/mnt/Storage/Media
        DOWNLOADS=/mnt/Storage/Downloads

# Check if running as root

        if [ "$(id -u)" != "0" ]; then
                echo "This script must be run as root" 1>&2
                exit 1
        fi

# Begin script

# Plex
	docker pull linuxserver/plex
	docker stop plex
	docker rm plex
        docker create \
        --name=plex \
        --net=host \
        -e VERSION=latest \
        -e PUID=1000 -e PGID=1000 \
        -e TZ=America/Toronto \
        -v $CONFIG/plex:/config \
        -v $MEDIA:/data \
        linuxserver/plex
	docker start plex

# CouchPotato
	docker pull linuxserver/couchpotato
        docker stop couchpotato
        docker rm couchpotato
        docker create \
        --name=couchpotato \
        -v $CONFIG/couchpotato:/config \
        -v $DOWNLOADS:/downloads \
        -v $MEDIA/Movies:/movies \
        -e PGID=1000 -e PUID=1000  \
        -e TZ=America/Toronto \
        -p 5050:5050 \
        linuxserver/couchpotato
	docker start couchpotato

# Sonarr
	docker pull linuxserver/sonarr
        docker stop sonarr
        docker rm sonarr
        docker create \
        --name sonarr \
        -p 8989:8989 \
        -e PUID=1000 -e PGID=1000 \
        -v /dev/rtc:/dev/rtc:ro \
        -v $CONFIG/sonarr:/config \
        -v $MEDIA/TV\ Shows:/tv \
        -v $DOWNLOADS:/downloads \
        linuxserver/sonarr
	docker start sonarr

# PlexPy
	docker pull linuxserver/plexpy
        docker stop plexpy
        docker rm plexpy
        docker create \
        --name=plexpy \
        -v $CONFIG/plexpy:/config \
        -v $CONFIG/plex/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
        -e PGID=1000 -e PUID=1000  \
        -e TZ=America/Toronto \
        -p 8181:8181 \
        linuxserver/plexpy
	docker start plexpy

# SABnzbd
	docker pull linuxserver/sabnzbd
        docker stop sabnzbd
        docker rm sabnzbd
        docker create \
        --name=sabnzbd \
        -v $CONFIG/sabnzbd:/config \
        -v $DOWNLOADS/Usenet:/downloads \
        -v $DOWNLOADS/Usenet/incomplete:/incomplete-downloads \
        -e PGID=1000 -e PUID=1000 \
        -e TZ=America/Toronto \
        -p 8080:8080 -p 9090:9090 \
        linuxserver/sabnzbd
	docker start sabnzbd

# Deluge
	docker pull linuxserver/deluge
        docker stop deluge
        docker rm deluge
        docker create \
        --name deluge \
        --net=host \
        -e PUID=1000 -e PGID=1000 \
        -e TZ=America/Toronto \
        -v $DOWNLOADS/Torrents:/downloads \
        -v $CONFIG/deluge:/config \
        linuxserver/deluge
	docker start deluge

# Jackett
	docker pull linuxserver/jackett
        docker stop jackett
        docker rm jackett
        docker create \
        --name=jackett \
        -v $CONFIG/jackett:/config \
        -v $DOWNLOADS/Torrents/watch:/downloads \
        -e PGID=1000 -e PUID=1000 \
        -e TZ=America/Toronto \
        -p 9117:9117 \
        linuxserver/jackett
	docker start jackett

# PlexRequests
	docker pull linuxserver/plexrequests
        docker stop plexrequests
        docker rm plexrequests
        docker create \
        --name=plexrequests \
        -v /etc/localtime:/etc/localtime:ro \
        -v $CONFIG/plexrequests:/config \
        -e PGID=1000 -e PUID=1000  \
        -e URL_BASE=/requests \
        -p 3000:3000 \
        linuxserver/plexrequests
	docker start plexrequests

# Nginx
	docker pull linuxserver/nginx
        docker stop nginx
        docker rm nginx
        docker create \
        --name=nginx \
        -v /etc/localtime:/etc/localtime:ro \
        -v $CONFIG/nginx:/config \
        -e PGID=1000 -e PUID=1000  \
        -p 80:80 -p 443:443 \
        linuxserver/nginx
	docker start nginx

# CrashPlan
	docker pull jrcs/crashplan
        docker stop crashplan
        docker rm crashplan
        docker run -d \
        --name crashplan \
        -h $HOSTNAME \
        -e TZ=America/Toronto \
        -p 4242:4242 -p 4243:4243 \
        -v $CONFIG/crashplan:/var/crashplan \
        -v $MEDIA:/media \
        -v $CONFIG:/docker \
        jrcs/crashplan:latest
	docker start crashplan
