class oar_frontend::config {
	user { "oar":
		groups => 'oar',
		commend => 'User for OAR',
		ensure => 'present',
		managed_home => 'true',
	}
	file { "/etc/oar/prologue":
		ensure => present,
		owner => 'root',
		group => 'root',
		require => Class["oar_frontend::install"],
		notify => Class["oar_frontend::service"],
	}
	file { "/etc/oar/epilogue":
		ensure => present,
		owner => 'root',
		group => 'root',
		require => Class["oar_frontend::install"],
		notify => Class["oar_frontend::service"],
	}
	file { "/home/oar/.ssh/config":
			ensure => present,
			owner => oar,
			groupe => oar,
	}
	file { "/home/oar/.ssh/authorized_keys":
			ensure => present,
			owner => oar,
			group => oar,
	}
	file { "/home/oar/.ssh/id_rsa":
			ensure => present,
			owner => oar,
			group => oar,
	}
	file { "/etc/apt/sources.list.d/oar.list":
			ensure => present,
			source =>"puppet:///modules/oar_frontend/oar.list"
}
