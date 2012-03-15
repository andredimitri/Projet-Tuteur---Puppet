class dhcp::config {
  file {
    "/etc/dhcp/dhcpd.conf":
    owner => "root",
    group => "root",
    source => "puppet:///dhcp/dhcpd.conf",
    mode => 644,
    require => Class["dhcp::install"],
    notify => Class["dhcp::service"],
  }
}