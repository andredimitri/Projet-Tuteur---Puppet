class oar_frontend::config {
	file { "/etc/oar/{prologue,epilogue}":
		ensure => present,
		require => Class["oar_frontend::install"],
		notify => Class["oar_frontend::service"],
	}
	file { "/home/oar/.ssh/{config,authorized_keys,id_rsa}":
		ensure => present,
}