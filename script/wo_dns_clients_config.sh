#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration des machines clientes
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
puppetmaster=`sed -n "1 p" couple`
ip_puppetmaster=`arp $puppetmaster | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
puppetclient=`sed -n "2 p" couple`
ip_puppetclient=`arp $puppetclient | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`

echo "server="$puppetmaster >> /etc/puppet/puppet.conf

echo " " >> /etc/hosts
echo "#ajout IP puppet" >> /etc/hosts
echo "$ip_puppetmaster $puppetmaster" >> /etc/hosts
echo "$ip_puppetclient $puppetclient" >> /etc/hosts

rm couple

exit 0