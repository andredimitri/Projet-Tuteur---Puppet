class apache::install {
  package { "apache2":
    ensure => present,
  }
}
