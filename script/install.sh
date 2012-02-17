#!/bin/bash


config_ssh () {
	echo "Host *-*-kavlan-"$vlan" *-*-kavlan-"$vlan".*.grid5000.fr"
	echo "    ProxyCommand ssh -a -x kavlan-"$vlan" nc -q 0 %h %p"
}


#Définition des chemins vers les fichiers exploités.
##Chemin du fichier liste des nodes réservées.
list_nodes="$HOME/scripts/fichiers/list_nodes"
##Chemin des fichiers listes des clients et des masters
puppetclients="$HOME/puppet/ressources/fichiers/puppetclients"
puppetmasters="$HOME/puppet/ressources/fichiers/puppetmasters"
##Chemin du dossier des scripts de configuration puppet(master/client)
scripts="$HOME/puppet/scripts"
##Chemin du dossier ressources des modules puppet
modules="$HOME/puppet/ressources/modules"


echo -n "Utiliser d'anciens fichiers d'installation (y/n) ? "
read choix

if [ $choix == "n" ]
then
	if [ -f $list_nodes ]; then rm $list_nodes; fi
	if [ -f $puppetmasters ]; then rm $puppetmasters; fi
	if [ -f $puppetclients ]; then rm $puppetclients; fi
fi


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Mise en place de KaVLAN
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Récupération du numéro VLAN
jobid=`oarstat | grep $USER | cut -d' ' -f1`
vlan=`kavlan -V -j $jobid `


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Vérification et configuration SSH de l'utilisateur
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##On regarde si le fichier .ssh existe
echo "Vérification de la configuration ssh de l'utilisateur "$USER
config_ssh >> $HOME/.ssh/config

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Préparation des nodes (KaVLAN-edit)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
echo "---"
echo "Liste des machines réservé:"
kavlan -l
if [ $choix == "n" ]; then kavlan -l > $list_nodes; fi
echo "---"
echo "Déploiement de l'environnement Linux, Debian Squeeze 64bit, sur toutes les machines réservé (Peut prendre plusieurs minutes)."
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES --vlan $vlan -d -V4 -k $HOME/.ssh/id_dsa.pub
echo "Copie des clés SSH vers toutes les machines."
cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys
echo $USER > $HOME/username
for node in $(cat $list_nodes)
do
	taktuk -l root -s -m $node broadcast exec [ 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys' ]
	scp $HOME/.ssh/id_dsa* root@$node:~/.ssh/
	scp $HOME/username root@$node:~/
done
echo "---"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Création des tunnels
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
taktuk -l root -s -f $puppetclients broadcast exec [ 'user=`cat username`; ssh -L 8080:proxy:3128 $user@`route -n | grep UG | tr -s " " | cut -d " " -f2`' ]                                  
taktuk -l root -s -f $puppetclients broadcast exec [ apt-get -o 'Acquire::http::Proxy="http://localhost:8080"' update ]


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Installation du master puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération du node master (premier de la liste)
if [ $choix == "n" ]; then sed -n "1 p" $list_nodes > $puppetmasters; fi
puppetmaster=`cat $puppetmasters `
##installation via APT des paquets serveur et agent de puppet. Notre serveur sera aussi son propre client
echo "Installation des paquets sur le serveur: "$puppetmaster
taktuk -l root -s -m $puppetmaster broadcast exec [ apt-get -q -y install puppet facter puppetmaster ]


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#installation des clients puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération des nodes clientes
if [ $choix == "n" ]; then cat $list_nodes | tail -n +2 >> $puppetclients; fi
##installation via APT des paquets agent de puppet pour les clients 
echo "Installation des paquets sur les machines clientes"
taktuk -l root -s -f $puppetclients broadcast exec [ apt-get -q -y install puppet facter ]


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Initialisation des fichiers de configuration
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##sur le master:
echo "Configuration du serveur et des machines clientes."
scp $list_nodes  root@$puppetmaster:~/
scp $scripts/master_config.sh  root@$puppetmaster:~/
taktuk -l root -m $puppetmaster broadcast exec [ 'sh master_config.sh' ]
##sur les clients:
for puppetclient in $(cat $puppetclients)
do
	echo $puppetmaster >> $HOME/couple
	echo $puppetclient >> $HOME/couple
	scp $HOME/couple  root@$puppetclient:~/
	scp $scripts/clients_config.sh  root@$puppetclient:~/
	taktuk -l root -m $puppetclient broadcast exec [ 'sh clients_config.sh' ]
	rm $HOME/couple
done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Déploiement des catalogues
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##synchronisations clients <-> master
###envoie des demandes de certificat
echo "Déploiement des catalogues."
taktuk -l root -f $puppetclients broadcast exec [ puppet agent --test ]
###signature des certificats
taktuk -l root -m $puppetmaster broadcast exec [ puppet cert --sign --all ]
##rapatriement des catalogues/modules/manifests sur le master
echo "Rapartriement des catalogues/modules/manifests sur "$puppetmaster
scp $modules/ root@$puppetmaster:/etc/puppet/
##attribution des rôles aux clients et ajout des clients dans nodes.pp

taktuk -l root -m $puppetmaster broadcast exec [ "bind=`sed -n '2 p' list_nodes`; echo node '$bind' { include bind } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ "dhcp=`sed -n '4 p' list_nodes`; echo node '$dhcp' { include dhcp } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ "mysql=`sed -n '3 p' list_nodes`; echo node '$mysql' { include mysql } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
taktuk -l root -m $puppetmaster broadcast exec [ "nfs=`sed -n '4 p' list_nodes`; echo node '$nfs' { include nfs } >> /etc/puppet/manifests/nodes.pp" ] 2>> $error
###récupération des catalogues
taktuk -l root -f $puppetclients broadcast exec [ puppet agent --test ] 2>> $error

echo "Attribution des rôles :"
echo "- "`sed -n '2 p' $list_nodes `" : bind9,"
taktuk -l root -m $puppetmaster broadcast exec [ "bind=`sed -n '2 p' /root/list_nodes`; echo node '$bind' { include bind } >> /etc/puppet/manifests/nodes.pp" ]
echo "- "`sed -n '3 p' $list_nodes `" : MySQL,"
taktuk -l root -m $puppetmaster broadcast exec [ "mysql=`sed -n '3 p' /root/list_nodes`; echo node '$mysql' { include mysql } >> /etc/puppet/manifests/nodes.pp" ] 
echo "- "`sed -n '4 p' $list_nodes `" : NFS."
taktuk -l root -m $puppetmaster broadcast exec [ "nfs=`sed -n '4 p' /root/list_nodes`; echo node '$nfs' { include nfs } >> /etc/puppet/manifests/nodes.pp" ]
###récupération des catalogues
taktuk -l root -m $puppetmaster broadcast exec [ "echo import 'nodes' >> /etc/puppet/manifests/site.pp" ]
taktuk -l root -f $puppetclients broadcast exec [ puppet agent --test ]

