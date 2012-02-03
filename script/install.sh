#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#Préparation des nodes
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Réservation des machines
oarsub -I -t deploy -l nodes=$1,walltime=$2
=======
#Formulaire
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo -n "Nombre de machine à réserver : "
read nbr_nodes
echo -n "Temps de la réservation (h:mm:ss) : "
read tmps

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Préparation des nodes
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Réservation des machines
oarsub -I -t deploy -l nodes=$nbr_nodes,walltime=$tmps

##Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES -k ~/.ssh/id_dsa.pub
##Mise à jour des machines
taktuk -s -f $OAR_FILE_NODES broadcast exec [ apt-get -y upgrade && update ]


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Installation du master puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération du node master (premier de la liste)
cat $OAR_FILE_NODES | sort -u | head -n 1 >> nodes
master=`sed -n "1 p" nodes`
##récupération et installtion du script depot_dashboard.sh
##Ajout du dépot apt.puppetlabs.com dans /etc/apt/sources.list

scp depot_dashboard.sh root@$master:~/
=======
scp $USER/scripts/depot_dashboard.sh root@$master:~/

taktuk -m $master broadcast exec [ sh ~/depot_dashboard.sh ]
##installation via APT des paquets serveur et agent de puppet. Notre serveur sera aussi son propre client
taktuk -m $master broadcast exec [ apt-get -y install puppet facter puppetmaster puppet-dashboard ]


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#installation des clients puppets
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récuperation des nodes clients (tout sauf le premier de la liste)
cat nodes | tail -n +2 >> clients
##installation via APT des paquets agent de puppet pour les clients 
for client in $(cat clients)
do

  taktuk -m $client broadcast exec [ apt-get -y install puppet facter ]
=======
	taktuk -m $client broadcast exec [ apt-get -y install puppet facter ]

done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Initialisation des fichiers de configuration
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##sur le master:
ip_master=`taktuk -m $master broadcast exec [ arp $master | cut -d' ' -f2 | cut -d'(' -f2 | cut -d')' -f1 ]`
taktuk -m $master broadcast exec [ echo "[master]" >> /etc/puppet/puppet.conf ]
taktuk -m $master broadcast exec [ echo "certname="$master >> /etc/puppet/puppet.conf ]
taktuk -m $master broadcast exec [ echo "#ajout IP puppet" >> /etc/hosts ]
taktuk -m $master broadcast exec [ echo $ip_master	$master >> /etc/hosts ]
##sur les clients:
for client in $(cat clients)
do
	ip_client=`taktuk -m $client broadcast exec [ arp $client | cut -d' ' -f2 | cut -d'(' -f2 | cut -d')' -f1 ]`	
	taktuk -m $client broadcast exec [ echo "server="$master >> /etc/puppet/puppet.conf ]
	taktuk -m $client broadcast exec [ echo "#ajout IP puppet" >> /etc/hosts ]
	taktuk -m $client broadcast exec [ echo $ip_client $client >> /etc/hosts ]
	taktuk -m $client broadcast exec [ echo $ip_master	$master >> /etc/hosts ]
	##vers le master:
	taktuk -m $master broadcast exec [ echo $ip_client $client >> /etc/hosts ]
done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Déploiement des catalogues
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##synchronisations clients <-> master
for client in $(cat clients)
do
	###envoie des demandes de certificat
	taktuk -m $client broadcast exec [ puppet agent --test ]
	###signature des certificats
	taktuk -m $master broadcast exec [ puppet cert --sign $client ]
done
##rapatriement des catalogues/modules/manifests sur le master

scp -r -p modules/ root@$master:/etc/puppet/
=======
scp -r -p $USER/ressources/modules/ root@$master:/etc/puppet/

##attribution des rôles aux clients
dns=`sed -n "1 p" clients`
mysql=`sed -n "2 p" clients`
##ajout des clients dans nodes.pp
taktuk -m $master broadcast exec [ echo "node '"$dns"' { include dns }" >> /etc/puppet/manifests/nodes.pp ]
taktuk -m $master broadcast exec [ echo "node '"$mysql"' { include mysql }" >> /etc/puppet/manifests/nodes.pp ]

for client in $(cat clients)
do
	###récupération des catalogues
	taktuk -m $client broadcast exec [ puppet agent --test ]
done
=======
###récupération des catalogues
taktuk -m $dns broadcast exec [ puppet agent --test ]
taktuk -m $mysql broadcast exec [ puppet agent --test ]
