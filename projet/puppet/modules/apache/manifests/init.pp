import 'install.pp'
import 'service.pp'

class apache {
  include apache::install,apache::service
}
