#!/bin/bash

# Check if running as root

	if [ "$(id -u)" != "0" ]; then
   		echo "This script must be run as root" 1>&2
   		exit 1
	fi

# Functions

function _installdocker() {
    curl -sSL https://get.docker.com/ | sh
}

function _createcontainers() {

    cp -R ../systemd/*.service /etc/systemd/system
    systemctl daemon-reload

    # Plex
	docker pull linuxserver/plex
        docker create \
        --name=plex \
        --net=host \
        -e VERSION=latest \
        -e PUID=$uid -e PGID=$gid \
        -e TZ=$timezone \
        -v $config/plex:/config \
        -v $media:/data \
        linuxserver/plex
	docker start plex
	systemctl enable plex

    # CouchPotato
	docker pull linuxserver/couchpotato
        docker create \
        --name=couchpotato \
        -v $config/couchpotato:/config \
        -v $downloads:/downloads \
        -v $media/Movies:/movies \
        -e PGID=$gid -e PUID=$uid  \
        -e TZ=$timezone \
        -p 5050:5050 \
        linuxserver/couchpotato
	docker start couchpotato
	systemctl enable couchpotato

    # Sonarr
	docker pull linuxserver/sonarr
        docker create \
        --name sonarr \
        -p 8989:8989 \
        -e PUID=$uid -e PGID=$gid \
        -v /dev/rtc:/dev/rtc:ro \
        -v $config/sonarr:/config \
        -v $media/TV\ Shows:/tv \
        -v $downloads:/downloads \
        linuxserver/sonarr
	docker start sonarr
	systemctl enable sonarr

    # PlexPy
	docker pull linuxserver/plexpy
        docker create \
        --name=plexpy \
        -v $config/plexpy:/config \
        -v $config/plex/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
        -e PGID=$gid -e PUID=$uid  \
        -e TZ=$timezone \
        -p 8181:8181 \
        linuxserver/plexpy
	docker start plexpy
	systemctl enable plexpy

    # SABnzbd
	docker pull linuxserver/sabnzbd
        docker create \
        --name=sabnzbd \
        -v $config/sabnzbd:/config \
        -v $downloads/Usenet:/downloads \
        -v $downloads/Usenet/incomplete:/incomplete-downloads \
        -e PGID=$gid -e PUID=$uid \
        -e TZ=$timezone \
        -p 8080:8080 -p 9090:9090 \
        linuxserver/sabnzbd
	docker start sabnzbd
	systemctl enable sabnzbd

    # Deluge
	docker pull linuxserver/deluge
        docker create \
        --name deluge \
        --net=host \
        -e PUID=$uid -e PGID=$gid \
        -e TZ=$timezone \
        -v $downloads/Torrents:/downloads \
        -v $config/deluge:/config \
        linuxserver/deluge
	docker start deluge
	systemctl enable deluge

    # Jackett
	docker pull linuxserver/jackett
        docker create \
        --name=jackett \
        -v $config/jackett:/config \
        -v $downloads/Torrents/watch:/downloads \
        -e PGID=$gid -e PUID=$uid \
        -e TZ=$timezone \
        -p 9117:9117 \
        linuxserver/jackett
	docker start jackett
	systemctl enable jackett

    # PlexRequests
	docker pull linuxserver/plexrequests
        docker create \
        --name=plexrequests \
        -v /etc/localtime:/etc/localtime:ro \
        -v $config/plexrequests:/config \
        -e PGID=$gid -e PUID=$uid  \
        -e URL_BASE=/requests \
        -p 3000:3000 \
        linuxserver/plexrequests
	docker start plexrequests
	systemctl enable plexrequests

    # Nginx
	docker pull linuxserver/nginx
        docker create \
        --name=nginx \
        -v /etc/localtime:/etc/localtime:ro \
        -v $config/nginx:/config \
        -e PGID=$gid -e PUID=$uid  \
        -p 80:80 -p 443:443 \
        linuxserver/nginx
	docker start nginx
	systemctl enable nginx

    # CrashPlan
	docker pull jrcs/crashplan
        docker run -d \
        --name crashplan \
        -h $HOSTNAME \
        -e TZ=$timezone \
        -p 4242:4242 -p 4243:4243 \
        -v $config/crashplan:/var/crashplan \
        -v $media:/media \
        -v $config:/docker \
        jrcs/crashplan:latest
	docker start crashplan
	systemctl enable crashplan

    sleep 60 # wait for containers to start

}

function _reverseproxy() {

    # CouchPotato
        docker stop couchpotato
        rm $config/couchpotato/config.ini
        cp ../apps/couchpotato/config.ini $config/couchpotato/
        docker start couchpotato

    # Jackett
        docker stop jackett
        rm $config/jackett/Jackett/ServerConfig.json
        cp ../apps/jackett/ServerConfig.json $config/jackett/Jackett/
        docker start jackett

    #PlexPy
        docker stop plexpy
        rm $config/plexpy/config.ini
        cp ../apps/plexpy/config.ini $config/plexpy/
        docker start plexpy

    # Sonarr
        docker stop sonarr
        rm $config/sonarr/config.xml
        cp ../apps/sonarr/config.xml $config/sonarr/
        docker start sonarr

}

function _nginx() {

	docker stop nginx
        rm $config/nginx/nginx/site-confs/default # Adjust IP in this file as needed
        cp ../nginx/default $config/nginx/nginx/site-confs/
        apt-get install -y apache2-utils
	htpasswd -b -c $config/nginx $user $password
        cp ../ssl/bergplex.* $config/nginx/keys
        docker start nginx

}

spinner() {
    local pid=$1
    local delay=0.25
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [${bold}${yellow}%c${normal}]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -ne "${OK}"
}

OK=$(echo -e "[ ${bold}${green}DONE${normal} ]")
echo
echo -n "##### BERGPLEX MEDIA SERVER SCRIPT #####";echo
echo
read -p "User for containers and basic auth?  " user
while true
do
    echo
    read -s -p "Create password " password
    echo
    read -s -p "Verify password " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again"
done
echo
echo -n "What is the path to docker container config files? (do not include trailing /) "; read config
echo
echo -n "What is the path to media files? (do not include trailing /) "; read media
echo
echo -n "What is the path to downloads? (do not include trailing /) "; read downloads
echo
echo -n "Installing docker ...";_installdocker >/dev/null 2>&1 & spinner $!;echo
usermod -aG docker $user
#newgrp docker
uid=$(id -u $user)
gid=$(id -g $user)
timezone=$(cat /etc/timezone)
echo
echo -n "Creating docker containers ...";_createcontainers >/dev/null 2>&1 & spinner $!;echo
echo
echo -n "Applying reverse proxy settings to containers ...";_reverseproxy >/dev/null 2>&1 & spinner $!;echo
echo
echo -n "Setting up nginx with basic authentication and SSL certificate ...";_nginx >/dev/null 2>&1 & spinner $!;echo
echo
echo -n "Setting permissions ..."; chown -R $user:$user $config $media $downloads & spinner $!;echo
echo
echo -n "Setup complete. Restore config data from CrashPlan now as needed. Ensure to stop affected containers first.";echo
echo
echo -n "Enjoy!";echo
echo
