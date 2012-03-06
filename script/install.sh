#!/bin/bash


config_ssh () {
	echo "Host *-*-kavlan-"$vlan" *-*-kavlan-"$vlan".*.grid5000.fr"
	echo "	ProxyCommand ssh -a -x kavlan-"$vlan" nc -q 0 %h %p"
}


#Définition des chemins vers les fichiers exploités.
##Chemin du fichier liste des nodes réservées.
list_nodes="$HOME/projet/install/list_nodes"
install_scripts="$HOME/projet/install"
##Chemin des fichiers listes des clients et des masters
puppet_fichiers="$HOME/projet/puppet/fichiers"
puppet_clients="$HOME/projet/puppet/fichiers/puppet_clients"
puppet_masters="$HOME/projet/puppet/fichiers/puppet_master"
##Chemin du dossier des scripts de configuration puppet(master/client)
puppet_scripts="$HOME/projet/puppet/scripts"
##Chemin du dossier ressources des modules puppet
puppet_modules="$HOME/projet/puppet/modules"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Mise en place de KaVLAN
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Activation du dhcp
kavlan -e
##Récupération du numéro VLAN
jobid=`oarstat | grep $USER | cut -d' ' -f1`
vlan=`kavlan -V -j $jobid `


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Vérification et configuration SSH de l'utilisateur
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##On regarde si le fichier .ssh existe
echo "---"
echo "Vérification de la configuration ssh de l'utilisateur "$USER

trouver=0

if [ -f $HOME/.ssh/config ]
then 
	trouver=1
	for line in $(cat $HOME/.ssh/config)
	do
		if [ $line = "kavlan-$vlan" ]
		then
			trouver=2
		fi
	done
else 
	echo "Erreur. Aucun fichier, .ssh/config, n'a pas été trouvé..."
	echo "Arrêt de l'installation."
	exit
fi

if [ $trouver -eq 1 ]
then 
	echo "Ajout des lignes de 'proxy commande'"
	config_ssh >> $HOME/.ssh/config
fi


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Préparation des nodes (KaVLAN-edit)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
echo "---"
echo "Liste des machines réservé:"
kavlan -l
echo "---"
echo "Déploiement de l'environnement Linux, Debian Squeeze 64bit, sur toutes les machines réservé (Peut prendre plusieurs minutes)."
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES --vlan $vlan -d -V4 -k $HOME/.ssh/id_dsa.pub &>/dev/null
echo "Copie des clés SSH vers toutes les machines."
cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys
for node in $(kavlan -l)
do
	scp $HOME/.ssh/id_dsa* root@$node:~/.ssh/
	taktuk -l root -s -m $node broadcast exec [ 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys' ] &>/dev/null
done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Création des tunnels
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "Création des tunnels SSH."
echo $USER > $HOME/username
for node in $(kavlan -l)
do
	scp $HOME/username root@$node:~/
	scp $install_scripts/tunnel.sh root@$node:~/
done
rm $HOME/username

kavlan -l > $list_nodes
taktuk -l root -s -f $list_nodes broadcast exec [ 'sh tunnel.sh; rm tunnel.sh username' ] &>/dev/null
echo "Mise à jour des dépots"
taktuk -l root -s -f $list_nodes broadcast exec [ apt-get update ] &>/dev/null
echo "---"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Installation du master puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération du node master (premier de la liste)
sed -n "1 p" $list_nodes > $puppet_masters
puppet_master=`cat $puppet_masters `
##installation via APT des paquets serveur et agent de puppet. Notre serveur sera aussi son propre client
echo "Installation des paquets sur le serveur: "$puppet_master
taktuk -l root -s -m $puppet_master broadcast exec [ apt-get -q -y install puppet facter puppetmaster ] &>/dev/null
##rapatriement des catalogues/modules/manifests sur le master
echo "Rapartriement des catalogues/modules/manifests sur "$puppet_master
scp -r $puppet_modules/ root@$puppet_master:/etc/puppet/
##attribution des rôles aux clients et ajout des clients dans nodes.pp
echo "Attribution des rôles effectués:"
echo "- "`sed -n '2 p' $list_nodes `" : bind9,"
echo "- "`sed -n '3 p' $list_nodes `" : MySQL,"
echo "- "`sed -n '4 p' $list_nodes `" : NFS."
echo "- "`sed -n '5 p' $list_nodes `" : OAR."


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#installation des clients puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération des nodes clientes
cat $list_nodes | tail -n +2 > $puppet_clients
##installation via APT des paquets agent de puppet pour les clients 
echo "Installation des paquets sur les machines clientes"
taktuk -l root -s -f $puppet_clients broadcast exec [ apt-get -q -y install puppet facter ] &>/dev/null


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Initialisation des fichiers de configuration
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##sur le master:
echo "Configuration du serveur et des machines clientes."
scp $list_nodes  root@$puppet_master:~/
scp $puppet_scripts/master_config.sh  root@$puppet_master:~/
taktuk -l root -m $puppet_master broadcast exec [ 'sh master_config.sh; rm master_config.sh list_nodes' ] &>/dev/null
##sur les clients:
for puppet_client in $(cat $puppet_clients)
do
	echo $puppet_master >> $HOME/couple
	echo $puppet_client >> $HOME/couple
	scp $HOME/couple  root@$puppet_client:~/
	scp $puppet_scripts/clients_config.sh  root@$puppet_client:~/
	taktuk -l root -m $puppet_client broadcast exec [ 'sh clients_config.sh; rm clients_config.sh couple' ] &>/dev/null
	rm $HOME/couple
done

echo "---"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Déploiement des catalogues
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##synchronisations clients <-> master
###envoie des demandes de certificat
echo "Déploiement des demandes de certificat."
taktuk -l root -f $puppet_clients broadcast exec [ puppet agent --test ] &>/dev/null
###signature des certificats
echo "signature des certificats."
taktuk -l root -m $puppet_master broadcast exec [ puppet cert --sign --all ] &>/dev/null
###récupération des catalogues
echo "récupération des catalogues"
taktuk -l root -f $puppet_clients broadcast exec [ puppet agent --test ] &>/dev/null
echo "---"
echo "Fin de déploiement"
