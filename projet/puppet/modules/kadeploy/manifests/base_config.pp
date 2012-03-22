class kadeploy::base::config {

  file {
    "/etc/apt/source.list.d/kadeploy.list":
      source  => "puppet:///kadeploy/kadeploy.list",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }

}