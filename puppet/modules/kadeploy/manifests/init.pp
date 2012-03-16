import 'base_install.pp'
import 'base_config.pp'
import 'client_install.pp'
import 'server_install.pp'

class kadeploy::base {
	include kadeploy::base::install,kadeploy::base::config
}

class kadeploy::client inherits kadeploy::base {
	include kadeploy::client::install
}

class kadeploy::server inherits kadeploy::base {
	include kadeploy::server::install
}