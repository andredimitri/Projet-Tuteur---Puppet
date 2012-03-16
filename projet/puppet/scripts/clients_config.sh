#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration des machines clientes
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
puppetmaster=`sed -n "1 p" couple`
ip_puppetmaster=`arp $puppetmaster | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
puppetclient=`sed -n "2 p" couple`
ip_puppetclient=`arp $puppetclient | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
num=`sed -n "3 p" couple`
role=`sed -n $num"p" roles`

echo "server=puppet.ptut-grid5000.lan" >> /etc/puppet/puppet.conf

echo " " >> /etc/hosts
echo "#ajout IP puppet" >> /etc/hosts
echo "$ip_puppetmaster puppet.ptut-grid5000.lan" >> /etc/hosts
echo "$ip_puppetclient $role.ptut-grid5000.lan" >> /etc/hosts

echo $role.ptut-grid5000.lan > /etc/hostname
/etc/init.d/hostname.sh start

rm couple

exit 0