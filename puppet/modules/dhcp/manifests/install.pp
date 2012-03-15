class dhcp::install {
  package { "dhcp3-server":
    ensure => present,
  }
}
