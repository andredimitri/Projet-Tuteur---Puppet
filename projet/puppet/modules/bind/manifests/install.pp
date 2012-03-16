class bind::install {
  package { "bind9":
    ensure => present,
  }
}