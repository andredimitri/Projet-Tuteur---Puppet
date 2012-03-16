class kadeploy::server::install {
  package {
    ["kadeploy-server","tftpd-hpa","syslinux"]:
      require => File["/etc/apt/source.list.d/kadeploy.list"],
      ensure => installed;
  }

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
  
  define files_syslinux() {
    exec {
      "cp /usr/lib/syslinux/$name /var/lib/tftpboot/":
        path    => "/usr/sbin:/usr/bin:/sbin:/bin",
        user    => root,
        creates => "/var/lib/tftpboot/$name",
        require => [Package["tftpd-hpa"],Packages["syslinux"]],
    }
  }

  files_kadeploy { ['conf','clusters','cmd','nodes','specific_conf_marocco','partition_file_marocco']: }

  define files_kadeploy() {
    file {
      "/etc/kadeploy3/$name":
        source  => "puppet:///kadeploy/confs/$name",
        ensure  => file,
        owner   => kadeploy,
        group   => kadeploy,
        mode    => 644,
        require => Package["kadeploy-server"];
    }
  }

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
      source  => "puppet:///kadeploy/authorized_keys",
      ensure  => file,
      owner   => kadeploy,
      group   => kadeploy,
      mode    => 644,
      require => File["/var/lib/kadeploy/.ssh"];
  }
}