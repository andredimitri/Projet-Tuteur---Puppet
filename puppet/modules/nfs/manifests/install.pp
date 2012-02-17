class nfs::install {
package { "nfs-kernel-server":
ensure => installed,
}
}