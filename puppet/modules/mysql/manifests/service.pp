class mysql::service {
  service { "mysql":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class["mysql::install"],
  }
}
