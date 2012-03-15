class dashboard::install {
  package { "puppet-dashboard":
    ensure => present,
  }
}