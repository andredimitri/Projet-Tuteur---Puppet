import 'install.pp'
import 'config.pp'
import 'service.pp'

class dashboard {
  include dashboard::install,dashboard::config,dashboard::service
}
