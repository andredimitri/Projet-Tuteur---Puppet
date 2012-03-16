class mysql::config {
  file {
    "/etc/mysql/my.cnf":
      source  => "puppet:///mysql/mysql-conf",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      notify  => Service["mysql"],
      require => Class["mysql::install"];

    "/root/init_deploy3-db":
      source  => "puppet:///kadeploy/init_deploy3-db",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }
}