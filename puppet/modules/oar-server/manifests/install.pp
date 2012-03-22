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
		source => "puppet:///oar-server/config";
	"/etc/ssh/sshd_config":
		ensure => file,
		mode => 0646,
		source => "puppet:///oar-server/sshd_config";
	"/var/lib/oar/.ssh/authorized_keys":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0644,
		source => "puppet:///oar-server/authorized_keys";
	"/var/lib/oar/.ssh/id_rsa":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar-server/id_rsa";
	"/var/lib/oar/.ssh/id_rsa.pub":
		ensure => file,
		owner => oar,
		group => oar,
		mode => 0400,
		source => "puppet:///oar-server/id_rsa.pub";
	"/etc/apt/sources.list.d/oar.list":
		ensure => file,
		mode => 0644,
		source =>"puppet:///oar-server/oar.list",
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
		source =>"puppet:///oar-server/oar.conf";
	}
}
