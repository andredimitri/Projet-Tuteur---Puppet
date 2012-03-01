import 'install.pp'
import 'config.pp'
import 'service.pp'

class oar_frontend {
include oar_frontend::install,oar_frontend::config,oar_frontend::service
}
