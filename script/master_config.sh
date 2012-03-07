#/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Configuration du serveur maitre
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#déclaration du nom serveur
puppetmaster=`cat list_nodes | head -n 1`

echo "[master]" >> /etc/puppet/puppet.conf
echo "certname="$puppetmaster >> /etc/puppet/puppet.conf

echo " " >> /etc/hosts
echo "#ajout IP puppet" >> /etc/hosts

#ajout des ip dans le fichier de conf du DNS
i=0
machine1=puppetmaster
machine2=bind
machine3=mysql
machine4=nfs
machine5=oar_frontend
machine6=kadeploy
for node in $(cat list_nodes)
do
	i++
	ip_node=`arp $node | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	if i > 6
		echo $ip_node > /
	else 
		echo $ip_node machine$i
	done 
done
#ajout des hosts clients
for node in $(cat list_nodes)
do
	ip_node=`arp $node | cut -d" " -f2 | cut -d"(" -f2 | cut -d")" -f1`
	echo $ip_node $node >> /etc/hosts
done

#attribution des rôles aux clients et ajout des clients dans nodes.pp
echo "node '`sed -n '2 p' list_nodes`' { include bind }" >> /etc/puppet/manifests/nodes.pp
echo "node '`sed -n '3 p' list_nodes`' { include mysql }" >> /etc/puppet/manifests/nodes.pp
echo "node '`sed -n '4 p' list_nodes`' { include nfs }" >> /etc/puppet/manifests/nodes.pp
echo "node '`sed -n '5 p' list_nodes`' { include oar }" >> /etc/puppet/manifests/nodes.pp
echo "import 'nodes.pp'" >> /etc/puppet/manifests/site.pp

exit 0
