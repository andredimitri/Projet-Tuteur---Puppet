#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Formulaire
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo -n "Nom de la réservation : "
read nom
echo -n "Nombre de machine à réserver : "
read nbr_nodes
echo -n "Temps de la réservation (h:mm:ss) : "
read tmps

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Réservation des machines
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "Réservation de "$nbr_nodes" machine(s) pour "$tmps" heure(s) sur un Vlan local."
oarsub -t deploy -l {"type='kavlan-local'"}/vlan=1+/nodes=$nbr_nodes,walltime=$tmps  -I -n "$nom"

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Activation du dhcp 
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
kavlan -e
