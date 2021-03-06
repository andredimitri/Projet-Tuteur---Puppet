# Module:: oar
# Manifest:: init.pp
#
# Author:: Quentin Dexheimer
# Date:: Wed Mar 14 09:56:11 +0100 2012
#

Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

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
		source => "puppet:///oar-frontend/config";
	"/etc/ssh/sshd_config":
		ensure => file,
		mode => 0646,
		source => "puppet:///oar-frontend/sshd_config";
	"/var/lib/oar/.ssh/authorized_keys":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0644,
		source => "puppet:///oar-frontend/authorized_keys";
	"/var/lib/oar/.ssh/id_rsa":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar-frontend/id_rsa";
	"/var/lib/oar/.ssh/id_rsa.pub":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar-frontend/id_rsa.pub";
	"/etc/apt/sources.list.d/oar.list":
		ensure => file,
		mode => 0644,
		source =>"puppet:///oar-frontend/oar.list",
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
