class nfs::install {
package { "nfs-kernel-server":
ensure => installed,
}
}
class nfs::service {
service { "nfs":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["nfs::install"],
}
}
class nfs {
include nfs::install,nfs::service
}
