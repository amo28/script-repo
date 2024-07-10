# @summary Manage rapid7 ir_agent
#
# Module for installing and managing Rapid7 Insight Agent (ir_agent).
# https://forge.puppet.com/modules/nvergottini/ir_agent/reference
#

# Set all of the following options in hiera
class profile::ir_agent {
  $ensure                    = lookup('profile::ir_agent::ensure')
  $checksum                  = lookup('profile::ir_agent::checksum')
  $checksum_type             = lookup('profile::ir_agent::checksum_type')
  $token                     = lookup('profile::ir_agent::token')
  $manage_auditd             = lookup('profile::ir_agent::manage_auditd')
  $semantic_version          = lookup('profile::ir_agent::semantic_version')

  class { '::ir_agent':
    source           => '{{ point to your specific installer script }}',
    token            => $token,
    checksum         => $checksum,
    checksum_type    => $checksum_type,
    manage_auditd    => $manage_auditd,
    semantic_version => $semantic_version,
    ensure           => $ensure,
  }

  file {'/opt/rapid7/ir_agent/components/insight_agent/common/config':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Service["ir_agent"],
  }

# See example json file
  file {'/opt/rapid7/ir_agent/components/insight_agent/common/config/excluded_paths.json':
    mode    => '0600',
    owner   => root,
    group   => root,
    notify  => Service["ir_agent"],
    source  => 'puppet:///modules/profile/ir_agent/excluded_paths.json',
    require => Service["ir_agent"],
  }

# Contact rapid7 to get this signature file
  file {'/opt/rapid7/ir_agent/components/insight_agent/common/config/excluded_paths.sig':
    mode    => '0600',
    owner   => root,
    group   => root,
    notify  => Service["ir_agent"],
    source  => 'puppet:///modules/profile/ir_agent/excluded_paths.sig',
    require => Service["ir_agent"],
  }
}
