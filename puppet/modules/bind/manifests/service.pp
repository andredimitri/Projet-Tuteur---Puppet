class bind::service {
service { "bind9":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["bind::install"],
}
}
