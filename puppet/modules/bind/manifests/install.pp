class bind::install {
package { [ "bind9", "bind9utils" ]:
ensure => present,
}
}
