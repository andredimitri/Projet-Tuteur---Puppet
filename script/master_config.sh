#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration du serveur maitre
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
puppetmaster=`cat list_nodes | head -n 1`

echo "[master]" >> /etc/puppet/puppet.conf
echo "certname="$puppetmaster >> /etc/puppet/puppet.conf

echo " " >> /etc/hosts
echo "#ajout IP puppet" >> /etc/hosts

for node in $(cat list_nodes)
do 
	ip_node=`arp $node | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	echo $ip_node $node >> /etc/hosts
done

exit 0