#!/bin/bash

# Check if running as root

if [ "$(id -u)" != "0" ]; then
echo "This script must be run as root" 1>&2
exit 1
fi

# Inputs

read -p "User for containers and basic authentication?  " user
while true
do
read -s -p "Create password " password
echo
read -s -p "Verify password " password2
[ "$password" = "$password2" ] && break
echo "Please try again"
done
echo
echo -n "What is your domain name? "; read domain
echo -n "What is your email address? "; read email
echo -n "What is the path to docker container config files? (do not include trailing /) "; read config
echo -n "What is the path to media files? (do not include trailing /) "; read media
echo -n "What is the path to downloads? (do not include trailing /) "; read downloads

# Variables

uid=$(id -u $user)
gid=$(id -g $user)
timezone=$(cat /etc/timezone)

# Install docker

apt-get update
apt-get upgrade -y
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

# Create and start containers

# Nginx
docker run -d \
--name nginx \
-p 80:80 -p 443:443 \
-v /etc/nginx/conf.d  \
-v /etc/nginx/vhost.d \
-v /usr/share/nginx/html \
-v $config/nginx/keys:/etc/nginx/certs:ro \
nginx

curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > $config/nginx/nginx.tmpl

# Nginx-gen
docker run -d \
--name nginx-gen \
--volumes-from nginx \
-v $config/nginx/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
jwilder/docker-gen \
-notify-sighup nginx -watch -only-exposed -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

# Nginx-letsencrypt
docker run -d \
--name nginx-letsencrypt \
-e "NGINX_DOCKER_GEN_CONTAINER=nginx-gen" \
-e "ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory" \
--volumes-from nginx \
-v $config/nginx/keys:/etc/nginx/certs:rw \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
jrcs/letsencrypt-nginx-proxy-companion

# Plex
docker run -d \
--name=plex \
--net=host \
-e VERSION=latest \
-e PUID=$uid -e PGID=$gid \
-e TZ=$timezone \
-v $config/plex:/config \
-v $media:/media \
linuxserver/plex

# CouchPotato
docker run -d \
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
linuxserver/couchpotato

# Sonarr
docker run -d \
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
linuxserver/sonarr

# PlexPy
docker run -d \
--name=plexpy \
-v $config/plexpy:/config \
-v $config/plex/Library/Application\ Support/Plex\ Media\ Server/Logs:/logs:ro \
-e PGID=$gid -e PUID=$uid  \
-e TZ=$timezone \
-p 8181:8181 \
-e VIRTUAL_HOST=plexpy.$domain \
-e LETSENCRYPT_HOST=plexpy.$domain \
-e LETSENCRYPT_EMAIL=$email \
linuxserver/plexpy

# SABnzbd
docker run -d \
--name=sabnzbd \
-v $config/sabnzbd:/config \
-v $downloads:/downloads \
-e PGID=$gid -e PUID=$uid \
-e TZ=$timezone \
-p 8080:8080 -p 9090:9090 \
-e VIRTUAL_HOST=sabnzbd.$domain \
-e LETSENCRYPT_HOST=sabnzbd.$domain \
-e LETSENCRYPT_EMAIL=$email \
linuxserver/sabnzbd

# Deluge
docker run -d \
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
linuxserver/deluge

# Jackett
docker run -d \
--name=jackett \
-v $config/jackett:/config \
-v $downloads:/downloads \
-e PGID=$gid -e PUID=$uid \
-e TZ=$timezone \
-p 9117:9117 \
-e VIRTUAL_HOST=jackett.$domain \
-e LETSENCRYPT_HOST=jackett.$domain \
-e LETSENCRYPT_EMAIL=$email \
linuxserver/jackett

# PlexRequests.NET
docker run -d -i \
--name=plexrequests \
--restart=always \
-p 3579:3579 \
-v $config/plexrequests:/config \
-e VIRTUAL_HOST=plexrequests.$domain \
-e LETSENCRYPT_HOST=plexrequests.$domain \
-e LETSENCRYPT_EMAIL=$email \
rogueosb/plexrequestsnet

# # CrashPlan
# docker run -d \
# --name crashplan \
# -h $HOSTNAME \
# -e TZ=$timezone \
# -p 4242:4242 -p 4243:4243 \
# -v $config/crashplan:/var/crashplan \
# -v $media:/media \
# -v $config:/docker \
# jrcs/crashplan:latest

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
    
# Setup systemd for nginx-letsencrypt as it does not have a folder in /opt
    
cat > /etc/systemd/system/nginx-letsencrypt.service << EOF
[Unit]
Description=nginx-letsencrypt container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker start -a nginx-letsencrypt
ExecStop=/usr/bin/docker stop -t 2 nginx-letsencrypt

[Install]
WantedBy=default.target
EOF
systemctl daemon-reload
systemctl enable nginx-letsencrypt

# Remove basic authentication for PlexRequests.NET

rm $config/nginx/htpasswd/plexrequests.$domain

# Restart Nginx and Let's Encrypt

systemctl restart nginx
docker restart nginx-letsencrypt

# Set permissions

chown -R $user:$user $config $media $downloads

echo "Done!"
