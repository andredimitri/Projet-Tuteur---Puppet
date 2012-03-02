import 'install.pp'
import 'config.pp'
import 'service.pp'

class oar_server {
include oar_server::install,oar_server::config,oar_server::service,
}
