import 'install.pp'
import 'service.pp'
import 'config.pp'

class nfs {
	include nfs::install,nfs::config,nfs::service
}
