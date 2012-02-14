import 'install.pp'
import 'config.pp'
import 'service.pp'

class mysql {
	include mysql::install, mysql::config, mysql::service
}