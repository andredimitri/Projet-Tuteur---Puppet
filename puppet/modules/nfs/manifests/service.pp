class nfs::service {
service { "nfs":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["nfs::install"],
}
}