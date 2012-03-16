class kadeploy::base::install {
  package {
    "kadeploy3-common":
      require => File["/etc/apt/source.list.d/kadeploy.list"],
      ensure => installed;
  }

  user {
    "kadeploy":
      ensure  => present,
      comment => "Kadeploy user",
      uid     => "1001",
      gid     => "oar",
      shell   => "/bin/sh",
      home    => "/var/lib/kadeploy",
      managehome => true;
      require => Group["oar"],
  }

  group { 
    "oar":
    ensure => present,
  }

} 
