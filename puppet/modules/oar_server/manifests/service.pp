class oar_server::service {
service { "oar_server":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["oar_server::install"],
}
}
