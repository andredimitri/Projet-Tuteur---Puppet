#!/bin/bash

#ajout du dépot apt.puppetslabs.com dans
##/etc/apt/sources.list
echo "#Depot ajouter pour puppet-dashboard" >> /etc/apt/sources.list
echo "deb http://apt.puppetlabs.com/ubuntu lucid main" >> /etc/apt/sources.list
echo "deb-src http://apt.puppetlabs.com/ubuntu lucid main" >> /etc/apt/sources.list

##ajout de la clé GPG
gpg --recv-key 8347A27F
gpg -a --export 8347A27F > /tmp/key
apt-key add /tmp/key

exit 0