# Module:: kadeploy3
# Manifest:: init.pp
#
# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Mon Mar 12 15:09:50 +0100 2012
#

# Class:: kadeploy3::base
#
#
class kadeploy3::base {
  package {
    "kadeploy3-common":
      require => File["/etc/apt/source.list.d/kadeploy.list"],
      ensure => installed;
  }
  file {
    "/etc/apt/source.list.d/kadeploy.list":
      source  => "puppet:///modules/kadeploy3/kadeploy.list",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }
  user {
    "kadeploy":
      ensure  => present,
      uid     => "1001",
      gid     => "1001",
      shell   => "/bin/sh",
      home    => "/var/lib/kadeploy",
      managehome => true;
  }
} # Class:: kadeploy3::base

# Class:: kadeploy3::client inherits kadeploy3::base
#
#
class kadeploy3::client inherits kadeploy3::base {
  package {
    "kadeploy-client":
      ensure => installed;
  }
  #TODO penser à ajouter kadeploy (user) au groupe oar

  file {
    "/etc/kadeploy3/client_conf":
      source  => "puppet:///modules/kadeploy3/client_conf",
      ensure  => file,
      owner   => kadeploy,
      group   => kadeploy,
      mode    => 644,
      require => Package["kadeploy-common"];
  }
} # Class:: kadeploy3::client inherits kadeploy3::base


# Class:: kadeploy3::server inherits kadeploy3::base
#
#
class kadeploy3::server inherits kadeploy3::base {
  package {
    ["kadeploy-server","tftpd-hpa","syslinux"]:
      require => File["/etc/apt/source.list.d/kadeploy.list"],
      ensure => installed;
  }
  # ------------ >8 ------------ #
  package {
    "mysql-server":
      ensure => installed;
  }
  service {
    "mysql":
      ensure  => running,
      enable  => true,
      require => Package["mysql-server"];
  }

  exec {
    "MySQL Kadeploy":
      command       => "/usr/bin/mysql --execute=\"CREATE DATABASE deploy3\";",
      user          => root,
      unless        => "/usr/bin/mysql --execute=\"SHOW DATABASES;\" | grep '^deploy3$'";
  }
  file {
    "/etc/mysql/my.cnf":
      source  => "puppet:///modules/mysql-conf",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      notify  => Service["mysql"],
      require => Package["mysql-server"];
    "/root/init_deploy3-db":
      source  => "puppet:///modules/init_deploy3-db",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }
  # ------------ >8 ------------ #

  file {
    "/var/lib/tftpboot":
      ensure  => link,
      target  => "/srv/tftp",
      owner   => root,
      group   => root,
      mode    => 0755;
    "/var/lib/tftpboot/kernels":
      ensure  => directory,
      owner   => root,
      group   => kadeploy,
      mode    => 0755,
      require => File["/var/lib/tftpboot"];
    "/var/lib/tftpboot/pxelinux.cfg":
      ensure  => directory,
      owner   => root,
      group   => kadeploy,
      mode    => 0755,
      require => File["/var/lib/tftpboot"];
  }

  files_syslinux { ['chain.c32','mboot.c32','pxelinux.0']: }

  # Define:: files_syslinux
  # Args::
  #
  define files_syslinux() {
    exec {
      "cp /usr/lib/syslinux/$name /var/lib/tftpboot/":
        path    => "/usr/sbin:/usr/bin:/sbin:/bin",
        user    => root,
        creates => "/var/lib/tftpboot/$name",
        require => [Package["tftpd-hpa"],Packages["syslinux"]],
    }
  } # Define: files_syslinux

  files_kadeploy { ['conf','clusters','cmd','nodes','specific_conf_marocco','partition_file_marocco']: }

  # Define:: files_kadeploy
  # Args::
  #
  define files_kadeploy() {
    file {
      "/etc/kadeploy3/$name":
        source  => "puppet:///modules/kadeploy3/confs/$name",
        ensure  => file,
        owner   => kadeploy,
        group   => kadeploy,
        mode    => 644,
        require => Package["kadeploy-server"];
    }
  } # Define: files_kadeploy

  # TODO penser à ajouter kadeploy (user) au groupe oar
  file {
    "/var/cache/kadeploy":
      ensure  => directory,
      owner   => root,
      group   => kadeploy,
      mode    => 0755;
    "/var/lib/kadeploy/.ssh":
      ensure  => directory,
      owner   => kadeploy,
      group   => kadeploy,
      mode    => 0755,
      require => User["kadeploy"];
    "/var/lib/kadeploy/.ssh/authorized_keys":
      source  => "puppet:///modules/kadeploy3/authorized_keys",
      ensure  => file,
      owner   => kadeploy,
      group   => kadeploy,
      mode    => 644,
      require => File["/var/lib/kadeploy/.ssh"];
  }

} # Class:: kadeploy3::server inherits kadeploy3::base
