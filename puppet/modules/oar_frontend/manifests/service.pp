class oar_server::service {
service { "oar_frontend":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["oar_frontend::install"],
}
}
