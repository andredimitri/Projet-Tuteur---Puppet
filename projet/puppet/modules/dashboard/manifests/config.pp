class dashboard::config {
  file {
    "/root/pubkey.gpg":
      source  => "puppet:///dashboard/pubkey.gpg",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }

  exec {
    "Import puppet key":
      command       => "/bin/cat /root/pubkey.gpg | /usr/bin/apt-key add -",
      user	  => root,
      require	  => File["/root/pubkey.gpg"];
  }

  custom::config {
    "Enable Dashboard":
      file  => "/etc/default/puppet-dashbaord",
      pattern => "START",
      line => "START=yes",
      engine => "replaceline";
    "Enable Dashboard Workers":
      file  => "/etc/default/puppet-dashbaord-workers",
      pattern => "START",
      line => "START=yes",
      engine => "replaceline";
  }
 
}
