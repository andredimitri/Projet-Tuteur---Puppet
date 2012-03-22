import 'base_install.pp'
import 'base_config.pp'
import 'client_install.pp'
import 'server_install.pp'

class kadeploy {
	include kadeploy::base::install,kadeploy::base::config
}

class kadeploy::client inherits kadeploy {
	include kadeploy::client::install
}

class kadeploy::server inherits kadeploy {
	include kadeploy::server::install
}