#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration du serveur puppet maitre
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

echo "puppet.ptut-grid5000.lan" > /ect/hostname
/etc/init.d/hostname.sh start

puppetmaster=`sed -n 1p puppet_clients`
echo "server=puppet.ptut-grid5000.lan" >> /etc/puppet/puppet.conf
echo "[master]" >> /etc/puppet/puppet.conf
echo "certname=puppet.ptut-grid5000.lan" >> /etc/puppet/puppet.conf

echo " " >> /etc/hosts
echo "#ajout IP puppet" >> /etc/hosts

#ajout des hosts clients
y=1
for role in "puppet" "dhcp" "dns" "mysql" "nfs" "oar" "kadeploy"
do
	node=`sed -n $y"p" puppet_clients`
	ip_node=`arp $node | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	echo "$ip_node $role.ptut-grid5000.lan" >> /etc/hosts
	y=$(($y+1))
done

#attribution des rôles aux clients et ajout des clients dans nodes.pp

echo "node 'puppet.ptut-grid5000.lan' { include apache, dashboard }" >> /etc/puppet/manifests/nodes.pp
j=2
for role in "dhcp" "bind" "mysql" "nfs" "oar" "kadeploy"
do
	node=`sed -n $j"p" puppet_clients`
	echo "node '$role.ptut-grid5000.lan' { include $role }" >> /etc/puppet/manifests/nodes.pp
	j=$(($j+1))
done
echo "import 'nodes.pp'" >> /etc/puppet/manifests/site.pp


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration des fichiers pour le module DNS
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#ajout d'information dans le named.conf.local
puppet=`sed -n 1p puppet_clients`
ip_complete=`arp $puppet | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`


echo zone "`echo $ip_complete | cut -d"." -f3`.`echo $ip_complete | cut -d"." -f2`.`echo $ip_complete | cut -d"." -f1`.in-addr.arpa" {  >> /etc/puppet/modules/bind/files/named.conf.local
echo '      type master;'  >> /etc/puppet/modules/bind/files/named.conf.local
echo '      notify no;'  >> /etc/puppet/modules/bind/files/named.conf.local
echo '      file "/etc/bind/db.revers";'  >> /etc/puppet/modules/bind/files/named.conf.local
echo '};' >> /etc/puppet/modules/bind/files/named.conf.local


#ajout des correspondances dans les fichiers de zones
##fichier db.ptut-grid5000.lan et db.revers
i=1
for role in "puppet" "dhcp" "bind" "mysql" "nfs" "oar" "kadeploy"
do
	node=`sed -n $i"p" puppet_clients`
	ip_node=`arp $node | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	echo "$role		IN		A		$ip_node" >> /etc/puppet/modules/bind/files/db.ptut-grid5000.lan
	ip_oct_4=`echo $ip_node |cut -d"." -f4 `
	echo "$ip_oct_4		IN		PTR		$role.ptut-grid5000.lan." >> /etc/puppet/modules/bind/files/db.revers 
	i=$(($i+1))
done

i=1
for machine in $(cat list_users)
do
	ip_machine=`arp $machine | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	echo "machine$i	IN		A		$ip_machine" >> /etc/puppet/modules/bind/files/db.ptut-grid5000.lan
	ip_oct_4=`echo $ip_machine |cut -d"." -f4 `
	echo "$ip_oct_4		IN		PTR		machine$i.ptut-grid5000.lan." >> /etc/puppet/modules/bind/files/db.revers
	 echo "marocco-$i.ptut.grid5000.fr $ip_machines marocco" >> /etc/puppet/modules/kadeploy3/files/confsnodes 	
	i=$(($i+1))
done

#Ajout d'information dans le fichier specific_conf_marocco dans kadeploy3

USER=`cat $HOME/username`
utilisateur=`echo "$USER" | tr "a-z" "A-Z"`
vlan=`tail -1 list_users | cut -d '-' -f4`

part1=KEY_$utilisateur
part2=$USER@kavlan-$vlan

sed -i s/KEY_RBLONDE/$part1/g /etc/puppet/modules/kadeploy3/files/confs/specific_conf_marocco
sed -i s/rblonde@kavlan-1/$part2/g /etc/puppet/modules/kadeploy3/files/confs/specific_conf_marocco

exit 0
