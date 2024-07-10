# @summary Configure SSSD for LDAP auth
#
class profile::sssd {

  include profile::ca_certificates

  $sssd_packages = $::operatingsystemmajrelease ? {
    default   => [ 'sssd', 'sssd-ldap', 'sssd-client', 'sssd-common', 'sssd-common-pac', 'sssd-tools', 'openldap', 'openldap-clients', 'oddjob-mkhomedir' ],
    '9'       => [ 'sssd', 'sssd-ldap', 'sssd-client', 'sssd-common', 'sssd-common-pac', 'sssd-tools', 'openldap', 'openldap-clients', 'oddjob-mkhomedir' ],
  }

  $sssd_uri = lookup('profile::ldap::sssd_uri')
  $use_vault = lookup('profile::sssd::use_vault', Boolean)
  if $use_vault {
    $vault_url = lookup('hiera::vault_url')

    vault_secret { '/tmp/ldap_vault_binddn':
      vault_address => $vault_url,
      vault_path    => 'global/secret/ldap/binddn',
      filter        => 'binddn',
    }
    vault_secret { '/tmp/ldap_vault_bindpw':
      vault_address => $vault_url,
      vault_path    => 'global/secret/ldap/bindpw',
      filter        => 'bindpw',
    }

    $sssd_binddn = $::ldap_vault_cache['binddn'] ? {
      undef   => '',
      default => $::ldap_vault_cache['binddn']
    }
    $sssd_bindpw = $::ldap_vault_cache['bindpw'] ? {
      undef   => '',
      default => $::ldap_vault_cache['bindpw']
    }

  } else {
    $sssd_binddn = lookup('profile::sssd::sssd_binddn')
    $sssd_bindpw = lookup('profile::sssd::sssd_bindpw')
  }

  $access_conf_entries = lookup('profile::sssd::access_conf_entries', Array[String])
  $package_manage      = lookup('profile::sssd::package_manage')
  $package_ensure      = lookup('profile::sssd::package_ensure')
  $service_manage      = lookup('profile::sssd::service_manage')
  $service_name        = lookup('profile::sssd::service_name')
  $service_ensure      = lookup('profile::sssd::service_ensure')
  $service_enable      = lookup('profile::sssd::service_enable')
  $sssd_ca_bundle      = lookup('profile::sssd::sssd_ca_bundle')

  if $package_manage {
    package { $sssd_packages:
      ensure => $package_ensure,
    }

    package { 'nss-pam-ldapd':
      ensure => 'absent'
    }
  }

  file {'/etc/sssd':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file {'/etc/security':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  exec { 'Authselect enable SSSD':
    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin:/root/bin',
    command => '/usr/bin/authselect select sssd with-mkhomedir with-files-domain --force',
    unless  => "grep -q 'sssd' /etc/authselect/authselect.conf",
  }

  file {'/etc/sssd/conf.d/authconfig-sssd.conf':
    mode    => '0600',
    owner   => root,
    group   => root,
    notify  => Service[$service_name],
    content => template('profile/sssd/sssd.conf.erb')
  }

  file { '/etc/security/access.conf':
    ensure  => 'present',
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('profile/sssd/access.conf.erb')
  }

  if $service_manage {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
    }
  }
}
