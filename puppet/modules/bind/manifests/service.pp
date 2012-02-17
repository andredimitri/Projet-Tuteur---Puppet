class bind::service {
service { "bind":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["bind::install"],
}
}