class oar_frontend::install {
package { ["oar-common","oar-keyring","oar-doc","oar-user","oar-node","taktuk"]:
ensure => installed,
}
}
