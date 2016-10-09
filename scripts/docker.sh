#!/bin/bash

# Variables

	USER=aberg

# Check if running as root

	if [ "$(id -u)" != "0" ]; then
   		echo "This script must be run as root" 1>&2
   		exit 1
	fi

# Begin script

	apt-get update
	apt-get -y upgrade
	apt-get install apt-transport-https ca-certificates
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
	systemctl enable docker
	usermod -aG docker $USER

echo "System will now reboot. Upon reboot, run containers.sh to complete installation."

	sleep 10
	reboot -h now
