class dashboard::config {
  file {
    "/root/pubkey.gpg":
      source  => "puppet:///dashboard/pubkey.gpg",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
      
    "/etc/apt/sources.list":
      source  => "puppet:///dashboard/sources.list",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
      
    "/etc/default/puppet-dashboard":
      source  => "puppet:///dashboard/puppet-dashboard",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
      
    "/etc/default/puppet-dashboarrd-workers":
      source  => "puppet:///dashboard/puppet-dashboard-workers",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }

  exec {
    "Import puppet key":
      command	=> "/bin/cat /root/pubkey.gpg | /usr/bin/apt-key add -",
      user		=> root,
      require	=> File["/root/pubkey.gpg"];

    "Apt Update":
      command	=> "/usr/bin/apt-get update",
      user		=> root,
  }
 
}
