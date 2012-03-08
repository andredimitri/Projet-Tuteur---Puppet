class nfs::install {
package { [ "nfs-kernel-server", "nfs-common" ]:
ensure => present,
}
}