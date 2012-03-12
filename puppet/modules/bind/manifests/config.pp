class bind::config {
        file { "/etc/bind/db.ptut.grid5000.fr" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/db.ptut.grid5000.fr",
                require => Class["bind::install"],
                notify => Class("bind::service"],
        }
        file { "/etc/bind/db.revers" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/db.revers",
                require => Class["bind::install"],
                notify => Class("bind::service"],
        }
        file { "/etc/bind/named.conf.ptut" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/named.conf.local",
                require => Class["bind::install"],
                notify => Class("bind::service"],
        }
        file { "/etc/bind/named.conf.options" :
                ensure => present,
                owner=>'root',
                group=>'root',
                mode=> 0600
                source => "puppet:///modules/bind/files/named.conf.options",
                require => Class["bind::install"],
                notify => Class["bind::service"],
        }
	file {"/etc/bind/named.conf" : 
		ensure => present,
		owne r=>'root',
		group =>'root',
		mode =>0600
		source =>"puppet:///modules/bind/files/named.conf";
		require =>Class["bind::install"],
		notify =>Class["bind::service"],
	}

