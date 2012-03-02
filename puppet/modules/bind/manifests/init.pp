import 'install.pp'
import 'service.pp'

class bind {
include bind::install,bind::service
}

