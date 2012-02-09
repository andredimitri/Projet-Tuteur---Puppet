class mysql::install {
package { "mysql":
ensure => present,
}
}
class mysql::service {
service { "mysql":
ensure => running,
hasstatus => true,
hasrestart => true,
enable => true,
require => Class["mysql::install"],
}
}
class mysql {
include mysql::install,mysql::service
}
