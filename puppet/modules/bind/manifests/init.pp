import 'install.pp'
import 'config.pp'
import 'service.pp'
class bind {
include bind::install,bind::config,bind::service
}

