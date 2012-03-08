class mysql::config {
file { "/etc/mysql/my.cnf":
owner => "mysql",
group => "mysql",
source => "puppet:///mysql/my.cnf",
mode => 644,
require => Class["mysql::install"],
notify => Class["mysql::service"],
}
}
