class nfs::config {
file { "/etc/exports":
owner => "root",
group => "root",
source => "puppet:///nfs/exports",
mode => 644,
require => Class["nfs::install"],
notify => Class["nfs::service"],
}
}
