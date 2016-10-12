#!/bin/bash

# Check if running as root

	if [ "$(id -u)" != "0" ]; then
   		echo "This script must be run as root" 1>&2
   		exit 1
	fi

# Functions

function _installdocker() {
	apt-get install -y apt-transport-https ca-certificates
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get purge -y lxc-docker
	apt-cache policy docker-engine
	apt-get update
	apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
	apt-get update
	apt-get install -y docker-engine
	service docker start
	groupadd docker
	usermod -aG docker $user
	systemctl enable docker
}

function _createcontainers() {

    # Create and start containers

    # Nginx-proxy
        docker pull jwilder/nginx-proxy
        docker run -d \
        -p 80:80 -p 443:443 \
        --name nginx \
	-v $config/nginx/htpasswd:/etc/nginx/htpasswd \
	-v $config/nginx/keys:/etc/nginx/certs:ro \
        -v /etc/nginx/vhost.d \
        -v /usr/share/nginx/html \
        -v /var/run/docker.sock:/tmp/docker.sock:ro \
        jwilder/nginx-proxy
        docker start nginx

    # Letsencrypt-nginx-proxy-companion
        docker pull jrcs/letsencrypt-nginx-proxy-companion
        docker run -d \
	--name letsencrypt
        -v $config/nginx/keys:/etc/nginx/certs:rw \
        --volumes-from nginx \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        jrcs/letsencrypt-nginx-proxy-companion
	docker start letsencrypt

    # Plex
	docker pull linuxserver/plex
        docker create \
        --name=plex \
        --net=host \
        -e VERSION=latest \
        -e PUID=$uid -e PGID=$gid \
        -e TZ=$timezone \
        -v $config/plex:/config \
        -v $media:/media \
        linuxserver/plex
	docker start plex

    # CouchPotato
	docker pull linuxserver/couchpotato
        docker create \
        --name=couchpotato \
        -v $config/couchpotato:/config \
        -v $downloads:/downloads \
        -v $media:/media \
        -e PGID=$gid -e PUID=$uid  \
        -e TZ=$timezone \
        -p 5050:5050 \
	-e VIRTUAL_HOST=couchpotato.$domain \
	-e LETSENCRYPT_HOST=couchpotato.$domain \
	-e LETSENCRYPT_EMAIL=$email \
	-e LETSENCRYPT_TEST=true
        linuxserver/couchpotato
	docker start couchpotato

    # Sonarr
	docker pull linuxserver/sonarr
        docker create \
        --name sonarr \
        -p 8989:8989 \
        -e PUID=$uid -e PGID=$gid \
        -v /dev/rtc:/dev/rtc:ro \
        -v $config/sonarr:/config \
        -v $media:/media \
        -v $downloads:/downloads \
	-e VIRTUAL_HOST=sonarr.$domain \
        -e LETSENCRYPT_HOST=sonarr.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
        linuxserver/sonarr
	docker start sonarr

    # PlexPy
	docker pull linuxserver/plexpy
        docker create \
        --name=plexpy \
        -v $config/plexpy:/config \
        -v $config/plex/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
        -e PGID=$gid -e PUID=$uid  \
        -e TZ=$timezone \
        -p 8181:8181 \
	-e VIRTUAL_HOST=plexpy.$domain \
        -e LETSENCRYPT_HOST=plexpy.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
        linuxserver/plexpy
	docker start plexpy

    # SABnzbd
	docker pull linuxserver/sabnzbd
        docker create \
        --name=sabnzbd \
        -v $config/sabnzbd:/config \
        -v $downloads:/downloads \
        -e PGID=$gid -e PUID=$uid \
        -e TZ=$timezone \
        -p 8080:8080 -p 9090:9090 \
	-e VIRTUAL_HOST=sabnzbd.$domain \
        -e LETSENCRYPT_HOST=sabnzbd.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
        linuxserver/sabnzbd
	docker start sabnzbd

    # Deluge
	docker pull linuxserver/deluge
        docker create \
        --name deluge \
	-p 8112:8112 \
	-p 58846:58846 \
	-p 58946:58946 \
        -e PUID=$uid -e PGID=$gid \
        -e TZ=$timezone \
        -v $downloads:/downloads \
        -v $config/deluge:/config \
	-e VIRTUAL_HOST=deluge.$domain \
        -e LETSENCRYPT_HOST=deluge.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
        linuxserver/deluge
	docker start deluge

    # Jackett
	docker pull linuxserver/jackett
        docker create \
        --name=jackett \
        -v $config/jackett:/config \
        -v $downloads:/downloads \
        -e PGID=$gid -e PUID=$uid \
        -e TZ=$timezone \
        -p 9117:9117 \
	-e VIRTUAL_HOST=jackett.$domain \
        -e LETSENCRYPT_HOST=jackett.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
        linuxserver/jackett
	docker start jackett

    # PlexRequests.NET
	docker pull rogueosb/plexrequestsnet
	docker run -d -i \
	--name=plexrequests \
	--restart=always \
	-p 3579:3579 \
	-v $config/plexrequests:/config \
	-e VIRTUAL_HOST=requests.$domain \
        -e LETSENCRYPT_HOST=requests.$domain \
        -e LETSENCRYPT_EMAIL=$email \
        -e LETSENCRYPT_TEST=true
	rogueosb/plexrequestsnet
	docker start plexrequests

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

    # Wait for containers to start

    sleep 60

    # Install htpasswd for basic authentication setup

    apt-get install -y apache2-utils

    # Setup systemd and basic authentication for each container

    for d in $config/* ; do
	dir=$(basename $d)
	cat > /etc/systemd/system/$dir.service << EOF
	[Unit]
	Description=$dir container
	Requires=docker.service
	After=docker.service

	[Service]
	Restart=always
	ExecStart=/usr/bin/docker start -a $dir
	ExecStop=/usr/bin/docker stop -t 2 $dir

	[Install]
	WantedBy=default.target
EOF
	systemctl daemon-reload
	systemctl enable $dir
	htpasswd -b -c $config/nginx/htpasswd/$dir.$domain $user $password
    done

    # Remove basic authentication for PlexRequests.NET

    rm $config/nginx/htpasswd/requests.$domain
    docker restart nginx
    docker restart letsencrypt
}

function _update() {
	apt-get update
	apt-get upgrade -y
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

# Begin script

OK=$(echo -e "[ ${bold}${green}DONE${normal} ]")
echo
echo -n "##### DOCKER-SERVER #####";echo
echo
read -p "User for containers and basic authentication?  " user
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
echo -n "What is your domain name? "; read domain
echo
echo -n "What is your email address? "; read email
echo
echo -n "What is the path to docker container config files? (do not include trailing /) "; read config
echo
echo -n "What is the path to media files? (do not include trailing /) "; read media
echo
echo -n "What is the path to downloads? (do not include trailing /) "; read downloads
echo
echo -n "Updating / upgrading system ...";_update >/dev/null 2>&1 & spinner $!;echo
echo
echo -n "Installing docker ...";_installdocker >/dev/null 2>&1 & spinner $!;echo
uid=$(id -u $user)
gid=$(id -g $user)
timezone=$(cat /etc/timezone)
echo
echo -n "Creating docker containers ...";_createcontainers >/dev/null 2>&1 & spinner $!;echo
echo
echo -n "Setting permissions ..."; chown -R $user:$user $config $media $downloads & spinner $!;echo
echo
echo -n "Setup complete.";echo
echo
echo -n "Replace contents of CrashPlan .ui_info on local system with:";echo
echo
echo $(cat $config/crashplan/id/.ui_info) > /home/$user/temp.txt
sed -i "s/0.0.0.0/$domain/" /home/$user/temp.txt
cat /home/$user/temp.txt
rm /home/$user/temp.txt
echo
echo -n "Enjoy!";echo
echo
echo -n "System will reboot in 30 seconds ...";echo
echo
sleep 30
reboot -h now
