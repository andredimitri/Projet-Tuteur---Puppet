#!/bin/bash

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Formulaire
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo -n "Nom de la réservation : "
read nom
echo -n "Nombre de machines à réserver : "
read nbr_nodes
echo -n "Temps de la réservation (h:mm:ss) : "
read tmps

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Réservation des machines
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
echo "Réservation de "$nbr_nodes" machine(s) pour "$tmps" heure(s)."
oarsub -I -t deploy -l {"type='kavlan-local'"}/vlan=1+/nodes=$nbr_nodes,walltime=$tmps -n "$nom"
