# Module:: oar
# Manifest:: init.pp
#
# Author:: Quentin Dexheimer
# Date:: Wed Mar 14 09:56:11 +0100 2012
#

# Class:: oar::base
#
#
class oar::base{
	user { "oar":
		ensure  => present,
		uid     => "1042",
		gid     => "1042",
		groups  => "kadeploy","oar",
		shell   => "/bin/sh",
		home    => "/var/lib/oar",
		managehome => true;
	}
	realize["oar"];
	
	file { 
	"/var/lib/oar/.ssh/config":
		ensure => present,
		owner => oar,
		groupe => oar,
		source => "puppet:///Modules/OAR/config",
	
	"/var/lib/oar/.ssh/authorized_keys":
		ensure => present,
		owner => oar,
		group => oar,
		source => "puppet:///Modules/OAR/authorized_keys",
	
	"/var/lib/oar/.ssh/id_rsa":
		ensure => present,
		owner => oar,
		group => oar,
		source => "puppet:///Modules/OAR/id_rsa",
	
	"/var/lib/oar/.ssh/id_rsa.pub":
		ensure => present,
		owner => oar,
		group => oar,
		source => "puppet:///Modules/OAR/id_rsa.pub",
	
	"/etc/apt/sources.list.d/oar.list":
		ensure => present,
		source =>"puppet:///modules/oar_frontend/oar.list",
	}
	
	package { 
	"oar-common":
		ensure => installed,
		require => File["/etc/apt/sources.list.d/oar.list"],
		require => Package["oar-keyring"],
	
	"oar-keyring":
		ensure => installed,
		require => File["/etc/apt/sources.list.d/oar.list"],
	}
}
	
# Class:: oar::frontend
#
#
	
class oar::frontend inherits oar::base{
	
	 require => User["oar"],
	 package { 
	 "oar-doc":
	 	ensure => installed,
	 	require => File["/etc/apt/sources.list.d/oar.list"],
	 	require => Package["oar-keyring"],
	 
	 "oar-user":
	 	ensure => installed,
	 	require => File["/etc/apt/sources.list.d/oar.list"],
	 	require => Package["oar-keyring"],
	 "oar-node":
	 	ensure => installed,
	 	require => File["/etc/apt/sources.list.d/oar.list"],
	 	require => Package["oar-keyring"],
	 
	 "taktuk":
	 	ensure => installed,
	 }
	 
	 file { 
	"/etc/oar/prologue":
		ensure => present,
		
		owner => 'root',
		group => 'root',
	 "/etc/oar/epilogue":
		ensure => present,
		owner => 'root',
		group => 'root',
	}
}


# Class:: oar::server
#
#
	
class oar::server inherits oar::base{

	package { 
	"oar-admin":
	 	ensure => installed,
	 	require => Class[oar::base],

	"oar-server":
	 	ensure => installed,
	 	require => Class[oar::base],
	
	"oar-web-status": 
	 	ensure => installed,
	 	require => Class[oar::base],
	
	"apache2":
		ensure => installed,	

	mysql-server":
		ensure => installed,
	}

	file { 
	"/etc/oar/monika.cgi":
		ensure => present,
		source => "puppet:///modules/OAR/monika.cgi",
	"/etc/oar/drawgantt.cgi":
		ensure => present,
		source => "puppet:///modules/OAR/drawgantt.cgi",
	"/etc/oar/oar.conf":
		ensure => present,
		source =>"puppet:///modules/OAR/oar.conf",	
	}
}
