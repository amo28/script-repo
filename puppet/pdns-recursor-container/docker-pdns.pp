# Class to include pdns-recursor container
class profiles::docker_pdns {

  # Get variables to determine config
  $enabled              = hiera('profiles::docker_pdns::enabled', 'false')
  $docker_image         = hiera('profiles::docker_pdns::docker_image', '{{ point to default container image location }}')
  $docker_tag           = hiera('profiles::docker_pdns::docker_tag', '4.7.3-1')
  $allow_from           = hiera('profiles::docker_pdns::allow_from', '')
  $local_address        = hiera('profiles::docker_pdns::local_address', '')
  $network_timeout      = hiera('profiles::docker_pdns::network_timeout', '')
  $forward_zones        = hiera('profiles::docker_pdns::forward_zones', '')

  validate_bool($enabled)

  if $enabled == true {
    $ensure_dir = 'directory'
    $ensure_file = 'file'
    $docker_ensure = 'present'
  } else {
    $ensure_dir = 'absent'
    $ensure_file = 'absent'
    $docker_ensure = 'absent'
  }

  # Setup config dir
  file {'/etc/pdns-recursor':
    ensure  => $ensure_dir,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    force   => true,
  }

  # Create pdns-recursor.conf
  file {'/etc/pdns-recursor/recursor.conf':
    ensure  => $ensure_file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    force   => true,
    content => template('profiles/docker_pdns/recursor.conf.erb'),
    require => File['/etc/pdns-recursor'],
  }

  # Create named.root file
  file {'/etc/pdns-recursor/named.root':
    ensure  => $ensure_file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    force   => true,
    source => 'puppet:///modules/profiles/docker_pdns/named.root',
    require => File['/etc/pdns-recursor'],
  }

  # Create forward.zone file
  file {'/etc/pdns-recursor/forward.zone':
    ensure  => $ensure_file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    force   => true,
    content => template('profiles/docker_pdns/forward.zone.erb'),
    require => File['/etc/pdns-recursor'],
  }

  ::docker::image { "$docker_image":
    image_tag => "$docker_tag"
  }

  ::docker::run { 'pdns_recursor':
    ensure           => $docker_ensure,
    image            => "${docker_image}:${docker_tag}",
    net              => host,
    restart_service  => true,
    volumes          => "/etc/pdns-recursor:/etc/pdns-recursor",
  }
}
