#!/bin/bash

#Réservation des machines
oarsub -I -t deploy -l nodes=$1,walltime=$2
#Déploiement du système d'exploitation Debian Squeeze-x64-base sur les nodes
kadeploy3 -e squeeze-x64-base -f $OAR_FILE_NODES -k ~/.ssh/id_dsa.pub
#Mise à jour des machines
taktuk -s -f $OAR_FILE_NODES broadcast exec [ apt-get upgrade ]
taktuk -s -f $OAR_FILE_NODES broadcast exec [ apt-get update ]
#installation des clients puppets
client=`cat $OAR_FILE_NODES | sort -u | tail -n +1`
taktuk -f $client broadcast exec [ apt-get -y install puppet facter ]
#Installation du master puppet
master=`cat $OAR_FILE_NODES | sort -u | head -n 1`
taktuk -m $master broadcast exec [ 
taktuk -m $master broadcast exec [ apt-get -y install puppet facter puppetmaster ]
{{DEPOT à INSTALLER puppet-dashboard}}


#Transfert des fichiers de configuration
#sur les clients:
ip_master=``
taktuk -s -f $client broadcast exec [ echo $ip_master	$master >> /etc/hosts ]
taktuk -s -f $client broadcast exec [ echo "server="$master >> /etc/puppet/puppet.conf ]

#Sur le master:
taktuk -m $master broadcast exec [ echo "certname="$master >> /etc/puppet/puppet.conf ]