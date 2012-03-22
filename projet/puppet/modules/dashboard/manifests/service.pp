class dashboard::service {
  service {
    ["puppet-dashboard","puppet-dashboard-workers"]:
      ensure  => running,
      require => Package["puppet-dashboard"];
  }
}