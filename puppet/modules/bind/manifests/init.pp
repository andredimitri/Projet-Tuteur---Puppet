import 'install.pp'
import 'service.pp'
import 'config.pp'
class bind {
include bind::install,bind::service,bind::config
}

