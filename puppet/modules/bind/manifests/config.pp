class bind::config {
        file { "/etc/bind/db.ptut.grid5000.fr" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/db.ptut.grid5000.fr",
                require => Class["ssh::install"],
                notify => Class("ssh::service"],
        }
        file { "/etc/bind/db.revers" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/db.revers",
                require => Class["ssh::install"],
                notify => Class("ssh::service"],
        }
        file { "/etc/bind/named.conf.local" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/named.conf.local",
                require => Class["ssh::install"],
                notify => Class("ssh::service"],
        }
        file { "/etc/bind/named.conf.options" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/named.conf.options",
                require => Class["ssh::install"],
                notify => Class("ssh::service"],
        }

}

