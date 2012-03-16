# Module:: oar
# Manifest:: init.pp
#
# Author:: Quentin Dexheimer
# Date:: Wed Mar 14 09:56:11 +0100 2012
#


#
#installer les paquets
#définir les node.pp
#définir les site.pp
#placer le module dans modules
#ajouter ce qu'il faut dans puppet.conf et /etc/hosts


Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }
#Class oar
#Superclasse pour appeller les deux autres modules
#
class oar{
  include oar::frontend
  include oar::server
}

# Class:: oar::base
#Packages communs aux deux types de serveurs
#

class oar::base{
	group { "oar":
		ensure => present;
	}
	
	user { "oar":
		ensure  => present,
		# TODO
		#groups  => ["kadeploy","oar"],
		groups  => "oar",
		shell   => "/bin/sh",
		home    => "/var/lib/oar",
		managehome => true;
	}
	
	file { 
	"/var/lib/oar/.ssh/config":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0644,
		source => "puppet:///oar/config";
	"/etc/ssh/sshd_config":
		ensure => file,
		mode => 0646,
		source => "puppet:///oar/sshd_config";
	"/var/lib/oar/.ssh/authorized_keys":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0644,
		source => "puppet:///oar/authorized_keys";
	"/var/lib/oar/.ssh/id_rsa":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar/id_rsa";
	"/var/lib/oar/.ssh/id_rsa.pub":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar/id_rsa.pub";
	"/etc/apt/sources.list.d/oar.list":
		ensure => file,
		mode => 0644,
		source =>"puppet:///oar/oar.list",
		#notify => Exec["updating"];
	}
	
	package { 
	"oar-keyring":
		ensure => installed,
		require => File["/etc/apt/sources.list.d/oar.list"];
	"oar-common":
		ensure => installed,
		require => [File["/etc/apt/sources.list.d/oar.list"],Package["oar-keyring"]];
		}
		exec { "apt-get update && apt-get install oar-common oar-keyring --allow-unauthenticated": 
		path => '/usr/bin:/bin:/usr/sbin:/sbin';
		}
}
	
# Class:: oar::frontend
#
# Classe pour l'installation de la machine de frontend
	
class oar::frontend inherits oar::base{
	 package { 
	 "oar-doc":
	 	ensure => installed,
	 	require => [File["/etc/apt/sources.list.d/oar.list"],Package["oar-keyring"]];
	 
	 "oar-user":
	 	ensure => installed,
	 	require => [File["/etc/apt/sources.list.d/oar.list"],Package["oar-keyring"]];
	 "oar-node":
	 	ensure => installed,
	 	require => [File["/etc/apt/sources.list.d/oar.list"],Package["oar-keyring"]];
	 
	 "taktuk":
	 	ensure => installed;
	 }
	 
	 file { 
	"/etc/oar/prologue":
		ensure => file,
		mode => 0644,
		owner => 'root',
		group => 'root';
	 "/etc/oar/epilogue":
		ensure => file,
		mode => 0644,
		owner => 'root',
		group => 'root';
	}
}


# Class:: oar::server
#
#Classe d'installation du serveur oar
	
class oar::server inherits oar::base{

	package { 
	["oar-admin","oar-server","oar-web-status","apache2"]:
	 	ensure => installed;
	}
	file { 
	"/etc/oar/oar.conf":
		ensure => file,
		mode => 0644,
		source =>"puppet:///oar/oar.conf";
	}
}
