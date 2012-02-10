#!/bin/bash


if [ -f $HOME/scripts/fichiers/list_nodes ]; then rm $HOME/scripts/fichiers/list_nodes; fi
if [ -f $HOME/puppet/ressources/fichiers/puppetmaster ]; then rm $HOME/scripts/fichiers/list_nodes; fi
if [ -f $HOME/puppet/ressources/fichiers/puppetclients ]; then rm $HOME/scripts/fichiers/list_nodes; fi

error="$HOME/scripts/fichiers/error.log"

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Mise en place de KaVLAN
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Activation du dhcp
kavlan -e
##Récupération du numéro VLAN
jobid=`oarstat | grep $USER | cut -d' ' -f1`
vlan=`kavlan -V -j $jobid `


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Préparation des nodes (KaVLAN-edit)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#cat $OAR_FILE_NODES | sort -u  > $HOME/scripts/fichiers/list_nodes
#list_nodes="$HOME/scripts/fichiers/list_nodes"
###Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
#echo "---"
#echo "Liste des machines réservé:"
#cat $list_nodes
#echo "---"
#echo "Déploiement de l'environnement Linux, Debian Squeeze 64bit, sur toutes les machines réservé (Peut prendre plusieurs minutes)."
#kadeploy3 -e squeeze-x64-base -f $list_nodes -k $HOME/.ssh/id_dsa.pub > /dev/null 2>&1

##Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
echo "---"
echo "Liste des machines réservé:"
kavlan -l
kavlan -l > $HOME/scripts/fichiers/list_nodes
list_nodes="$HOME/scripts/fichiers/list_nodes"
echo "---"
echo "Déploiement de l'environnement Linux, Debian Squeeze 64bit, sur toutes les machines réservé (Peut prendre plusieurs minutes)."
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES --vlan $vlan -d -V4 -k $HOME/.ssh/id_dsa.pub 2>> $error
echo "Copie des clés SSH vers toutes les machines."
for node in $(cat $list_nodes)
do
	scp $HOME/.ssh/id_dsa* root@$node:~/.ssh/ 2>> $error
done
echo "---"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Création des tunnels
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Installation du master puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération du node master (premier de la liste)
sed -n "1 p" $list_nodes > $HOME/puppet/ressources/fichiers/puppetmaster
puppetmaster=`cat $HOME/puppet/ressources/fichiers/puppetmaster`
##installation via APT des paquets serveur et agent de puppet. Notre serveur sera aussi son propre client
echo "Installation des paquets sur le serveur: "$puppetmaster
taktuk -l root -s -m $puppetmaster broadcast exec [ apt-get -q -y install puppet facter puppetmaster ] 2>> $error


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#installation des clients puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération des nodes clientes
cat $list_nodes | tail -n +2 >> $HOME/puppet/ressources/fichiers/puppetclients
puppetclients="$HOME/puppet/ressources/fichiers/puppetclients"
##installation via APT des paquets agent de puppet pour les clients 
echo "Installation des paquets sur les machines clientes"
taktuk -l root -s -f $puppetclients broadcast exec [ apt-get -q -y install puppet facter ] 2>> $error


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Initialisation des fichiers de configuration
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##sur le master:
echo "Configuration du serveur et des machines clientes."
scp $list_nodes  root@$puppetmaster:~/ > /dev/null 2>&1
scp $HOME/puppet/scripts/master_config.sh  root@$puppetmaster:~/ 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ 'sh master_config.sh' ] 2>> $error
##sur les clients:
for puppetclient in $(cat $puppetclients)
do
	echo $puppetmaster >> $HOME/puppet/ressources/fichiers/couple 2>> $error
	echo $puppetclient >> $HOME/puppet/ressources/fichiers/couple 2>> $error
	scp $HOME/puppet/ressources/fichiers/couple  root@$puppetclient:~/ 2>> $error
	scp $HOME/puppet/scripts/clients_config.sh  root@$puppetclient:~/ 2>> $error
	taktuk -l root -m $puppetclient broadcast exec [ 'sh clients_config.sh' ] 2>> $error
	rm $HOME/puppet/ressources/fichiers/couple 2>> $error
done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Déploiement des catalogues
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##synchronisations clients <-> master
###envoie des demandes de certificat
echo "Déploiement des catalogues."
taktuk -l root -f $puppetclients broadcast exec [ puppet agent --test ] 2>> $error
###signature des certificats
taktuk -l root -m $puppetmaster broadcast exec [ puppet cert --sign --all ] 2>> $error
##rapatriement des catalogues/modules/manifests sur le master
scp -R $HOME/puppet/ressources/modules/ root@$puppetmaster:/etc/puppet/
##attribution des rôles aux clients et ajout des clients dans nodes.pp
taktuk -l root -m $puppetmaster broadcast exec [ "bind=`sed -n '2 p' list_nodes`; echo node '$bind' { include bind } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ "mysql=`sed -n '3 p' list_nodes`; echo node '$mysql' { include mysql } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ "nfs=`sed -n '4 p' list_nodes`; echo node '$nfs' { include nfs } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
###récupération des catalogues
taktuk -l root -f $puppetclients broadcast exec [ puppet agent --test ] 2>> $error