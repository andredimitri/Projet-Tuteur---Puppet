#!/bin/bash


## Organisation des fichiers créés lors du script d'installation
# list_nodes		=> listes toutes les machines du VLAN
# list_users 		=> listes toutes les machines utilisateurs
# puppet_masters 	=> liste la machine puppet serveur
# puppet_clients 	=> listes des machines serveurs (DHCP, DNS, BdD, NFS, OAR, Kadeploy)


config_ssh () {
	echo "Host *-*-kavlan-"$vlan" *-*-kavlan-"$vlan".*.grid5000.fr"
	echo "	ProxyCommand ssh -a -x kavlan-"$vlan" nc -q 0 %h %p"
}


#Définition des chemins vers les fichiers exploités.
echo "Génération des variables..."
##Chemin du fichier liste des nodes réservées.
list_nodes="$HOME/projet/install/list_nodes"
list_users="$HOME/projet/install/list_users"
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
##Activation du DHCP g5k
kavlan -e
##Récupération du numéro VLAN
jobid=`oarstat | grep $USER | cut -d' ' -f1`
vlan=`kavlan -V -j $jobid `
site=`uname -n | cut -d"." -f2`
##Génération du fichier de configuration du DHCP
export GEM_HOME=/home/$USER/.gem/ruby/1.8/
gem install ruby-ip --no-ri --no-rdoc --user-install #&>/dev/null
chmod +x ./projet/install/gen_dhcpd_conf.rb #&>/dev/null
./projet/install/gen_dhcpd_conf.rb --site $site --vlan-id $vlan #&>/dev/null
mv dhcpd-kavlan-$vlan-$site.conf $puppet_modules/dhcp/files/dhcpd.conf


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Préparation des nodes (KaVLAN-edit)
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
echo "-=-=-"
echo "Liste des machines réservé:"
kavlan -l

##récupération de toutes les nodes.
kavlan -l > $list_nodes
##récupération de la node master.
cp $list_nodes $list_users
sed -n "1 p" $list_users > $puppet_clients 
sed -i "1 d" $list_users
##récupération des nodes clientes.
cp $puppet_clients $puppet_masters
for i in `seq 1 6`
do
	sed -n '1p' $list_users >> $puppet_clients
	sed -i '1d' $list_users
done

echo "-=-=-"
echo "Déploiement de l'environnement Linux, Debian Squeeze 64bit, sur toutes les machines réservé (Peut prendre plusieurs minutes)."
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES --vlan $vlan -d -V4 -k $HOME/.ssh/id_dsa.pub &>/dev/null
echo "-=-=-"


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Vérification et configuration SSH de l'utilisateur
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "Configuration ssh:"
echo " - Vérification de la configuration ssh (.ssh/config) de l'utilisateur "$USER

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
	echo "Erreur. Aucun fichier .ssh/config n'a pas été trouvé..."
	echo "Arrêt de l'installation."
	exit
fi

if [ $trouver -eq 1 ]
then 
	echo " - Ajout des lignes de 'proxy commande'"
	config_ssh >> $HOME/.ssh/config
fi


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Vérification et configuration SSH de l'utilisateur
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo " - Vérification des clé ssh authorisées (.ssh/authorized_keys) de l'utilisateur "$USER

trouver=0

if [ -f $HOME/.ssh/id_dsa.pub ]
then
	id_dsa=`cat .ssh/id_dsa.pub`
	if [ -f $HOME/.ssh/authorized_keys ]
	then 
		trouver=1
		for line in $(cat $HOME/.ssh/authorized_keys)
		do
			if [ "$line" = "$id_dsa" ]
			then
				trouver=2
			fi
		done
	else 
		echo "Erreur. Aucun fichier .ssh/authorized_keys n'a pas été trouvé..."
		echo "Arrêt de l'installation."
		exit
	fi
else
	echo "Erreur. Aucun fichier .ssh/id_dsa.pub n'a pas été trouvé..."
	echo "Arrêt de l'installation."
	exit	
fi

if [ $trouver -eq 1 ]
then 
	echo " - Ajout de la clé privé dans le fichier authorized_keys."
	cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys
fi


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Vérification et configuration SSH de l'utilisateur
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo " - Copie des clés SSH vers toutes les machines."
for node in $(cat $puppet_clients)
do
	scp $HOME/.ssh/id_dsa* root@$node:~/.ssh/ #&> lol.tmp
	taktuk -l root -s -m $node broadcast exec [ 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys' ] #&>/dev/null
done


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Création des tunnels
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "Création des tunnels SSH."
echo $USER > $HOME/username
for node in $(cat $puppet_clients)
do
	scp $HOME/username root@$node:~/ #&> lol.tmp
	scp $install_scripts/tunnel.sh root@$node:~/ #&> lol.tmp
done
rm $HOME/username

taktuk -l root -s -f $puppet_clients broadcast exec [ 'sh tunnel.sh' ] #&>/dev/null
echo "-=-=-"
echo "Mise à jour des dépots"
taktuk -l root -s -f $puppet_clients broadcast exec [ apt-get -q -y update ] #&>/dev/null


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Installation du master puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##récupération du node master (premier de la liste)
puppet_master=`cat $puppet_masters `
##installation via APT des paquets serveur et agent de puppet. Notre serveur sera aussi son propre client
echo "Installation des paquets sur le serveur: "$puppet_master
taktuk -l root -s -m $puppet_master broadcast exec [ apt-get -q -y install puppet facter puppetmaster ] #&>/dev/null 
##rappatriement des catalogues/modules/manifests sur le master
echo "Rappariement des catalogues/modules/manifests sur "$puppet_master
scp -r $puppet_modules/ root@$puppet_master:/etc/puppet/ #&> lol.tmp
##attribution des rôles aux clients et ajout des clients dans nodes.pp
echo "Attribution des rôles effectués:"
echo "- "`sed -n '2 p' $puppet_clients `" : dhcp,"
echo "- "`sed -n '3 p' $puppet_clients `" : bind,"
echo "- "`sed -n '4 p' $puppet_clients `" : mysql,"
echo "- "`sed -n '5 p' $puppet_clients `" : nfs,"
echo "- "`sed -n '6 p' $puppet_clients `" : oar,"
echo "- "`sed -n '7 p' $puppet_clients `" : kadeploy." 


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#installation des clients puppet
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##installation via APT des paquets agent de puppet pour les clients 
echo "Installation des paquets sur les machines clientes"
taktuk -l root -s -f $puppet_clients broadcast exec [ apt-get -q -y install puppet facter ] #&>/dev/null


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Initialisation des fichiers de configuration
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
##sur le master:
echo "Configuration du serveur et des machines clientes."
scp $puppet_clients  root@$puppet_master:~/ #&> lol.tmp
scp $list_users  root@$puppet_master:~/ #&> lol.tmp
scp $puppet_scripts/master_config.sh  root@$puppet_master:~/ #&> lol.tmp
taktuk -l root -m $puppet_master broadcast exec [ 'sh master_config.sh' ] #&>/dev/null
##sur les clients:
sed -i 1d $puppet_clients
n=2
for puppet_client in $(cat $puppet_clients)
do
	echo $puppet_master >> $HOME/couple
	echo $puppet_client >> $HOME/couple
	echo $n >> $HOME/couple
	scp $HOME/couple  root@$puppet_client:~/ #&> lol.tmp
	scp $puppet_fichiers/roles root@$puppet_client:~/ #&> lol.tmp
	scp $puppet_scripts/clients_config.sh  root@$puppet_client:~/ #&> lol.tmp
	taktuk -l root -m $puppet_client broadcast exec [ 'sh clients_config.sh' ] #&>/dev/null
	rm $HOME/couple
	n=$(($n+1))
done

echo "-=-=-"


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


#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Fini du script, redémarrage des services installé
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
###Désactivation du DHCP g5k
kavlan -d
###Rédémarrage du service réseau des clients. Pour le nouveau DHCP et pour le NFS.
echo "Redémarrage des services"
#taktuk -l root -s -m `sed -n '4 p' $puppet_clients ` broadcast exec [ /etc/init.d/nfs-kernel-server reload ] &>/dev/null
sed -i 1d $puppet_clients
taktuk -l root -s -f $puppet_clients broadcast exec [ dhclient ] &>/dev/null
taktuk -l root -s -f $list_users broadcast exec [ dhclient ] &>/dev/null
rm lol.tmp
echo "-=-=-"
echo "Fin de déploiement"