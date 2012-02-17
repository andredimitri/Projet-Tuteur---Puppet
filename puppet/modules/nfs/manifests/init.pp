import 'install.pp'
import 'config.pp'
import 'service.pp'

class nfs {
include nfs::install,nfs::service
}
