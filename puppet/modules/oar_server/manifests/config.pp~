class oar_server::config {
	file { "/etc/oar/{monika,drawgantt}.cgi":
		ensure => present,
		require => Class["oar_server::install"],
		notify => Class["oar_server::service"],
	}
	file { "(oar) ~/.ssh/{config,authorized_keys,id_rsa}":
		ensure => present,
		pattern => "Almigthy"
}
