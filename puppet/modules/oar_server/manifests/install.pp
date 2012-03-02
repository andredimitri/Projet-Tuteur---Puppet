class oar_server::install {
package {  ["oar-common","oar-keyring","oar-admin","oar-server"]:
ensure => installed,

package { ["oar-web-status","apache2"]:
ensure => installed,
}
}
