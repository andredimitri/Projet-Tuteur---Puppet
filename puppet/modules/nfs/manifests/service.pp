class nfs::service {
service { "nfs-kernel-server":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["nfs::install"],
}
}