class bind::config {
  file { 
	  "/etc/bind/named.conf.local":
		 owner => "root",
		 group => "root",
		 source => "puppet:///bind/named.conf.local",
		 mode => 644,
		 require => Class["bind::install"],
		 notify => Class["bind::service"];

	  "/etc/bind/named.conf.options":
		 owner => "root",
		 group => "root",
		 source => "puppet:///bind/named.conf.options",
		 mode => 644,
		 require => Class["bind::install"],
		 notify => Class["bind::service"];
	
	  "/etc/bind/db.ptut-grid5000.lan":
	    owner => "root",
	    group => "root",
	    source => "puppet:///bind/db.ptut-grid5000.lan",
	    mode => 644,
	    require => Class["bind::install"],
	    notify => Class["bind::service"];
	 
	  "/etc/bind/db.revers":
	    owner => "root",
	    group => "root",
	    source => "puppet:///bind/db.revers",
	    mode => 644,
	    require => Class["bind::install"],
	    notify => Class["bind::service"];
  }
}