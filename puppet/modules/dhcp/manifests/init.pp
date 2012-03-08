import 'install.pp'
import 'config.pp'
import 'service.pp'

class dhcp {
include dhcp::install,dhcp::config,dhcp::service
}
