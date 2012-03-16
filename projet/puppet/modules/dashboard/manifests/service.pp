class dashboard::service {
  service {
    ["puppet-dashbaord","puppet-dashboard-workers"]:
      ensure  => running,
      require => Package["puppet-dashboard"];
  }
}