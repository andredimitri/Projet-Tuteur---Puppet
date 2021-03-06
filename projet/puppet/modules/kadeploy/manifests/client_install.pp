class kadeploy::client::install {
  package {
    "kadeploy-client":
      ensure => installed;
  }

  file {
    "/etc/kadeploy3/client_conf":
      source  => "puppet:///kadeploy/client_conf",
      ensure  => file,
      owner   => kadeploy,
      group   => kadeploy,
      mode    => 644,
      require => Package["kadeploy-common"];
  }
}