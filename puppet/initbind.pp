class bind::install {
package { "bind9":
ensure => present,
}
}
class bind::service {
service { "bind":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["bind::install"],
}
}
class bind {
include bind::install,bind::service
}

