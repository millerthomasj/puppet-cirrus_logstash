class cirrus_logstash::tls
{
  user { 'logstash':
    ensure => present,
    groups => 'puppet',
  }

  $logstash_allow_from_beats_sites = $cirrus_logstash::logstash_allow_from_beats_sites
  validate_array($logstash_allow_from_beats_sites)

  $ca_cert_dir = '/etc/logstash/tls'
  $ca_options = { bfd01    => "${ca_cert_dir}/ca-bfd01.pem",
                  bfd02    => "${ca_cert_dir}/ca-bfd02.pem",
                  chrcnc01 => "${ca_cert_dir}/ca-chrcnc01.pem",
                  chrcnc02 => "${ca_cert_dir}/ca-chrcnc02.pem",
                  dev01    => "${ca_cert_dir}/ca-dev01.pem",
                  dev02    => "${ca_cert_dir}/ca-dev02.pem",
                  dnvrco01 => "${ca_cert_dir}/ca-dnvrco01.pem",
                  dnvrco02 => "${ca_cert_dir}/ca-dnvrco02.pem",
                  hrn01    => "${ca_cert_dir}/ca-hrn01.pem",
                  hrn02    => "${ca_cert_dir}/ca-hrn02.pem",
                  }
  $ca_options_keys = keys($ca_options)

  # Find the intersection of $ca_options_keys with $logstash_allow_from_beats_sites.
  # Assume the intersection is the list of sites we actually want to allow.
  # Delete the intersection from the list of all options ( $ca_options_keys ), then delete
  # the keys for the remaining options to produce a hash with only the keys we want.
  # ... because Puppet DSL.

  $ca_intersection = intersection($ca_options_keys, $logstash_allow_from_beats_sites)
  $ca_disallowed = delete($ca_options_keys, $ca_intersection)
  $ca_allowed = delete($ca_options, $ca_disallowed)
  # Use $ca_allowed_values as array value for ssl_certificat_authorities in cirrus_logstash
  # template 'input-filebeat.conf.erb'.
  $_ca_allowed_values = values($ca_allowed)

  # Safeguard against a failed or misguided Hiera lookup from breaking intra-site logging.
  # Ensure that Logstash trusts the CA cert used by Puppet -- vice the CA cert stored in
  # Hiera -- if cross-site Filebeat-to-Logstash comms are not required.
  if (size($ca_allowed) == 0) or ((size($ca_allowed) == 1) and has_key($ca_allowed, $::cirrus_site_iteration)) {
    $ca_allowed_values = [ '/var/lib/puppet/ssl/certs/ca.pem' ]

    file { $ca_cert_dir:
      ensure => absent,
      force  => true,
    }
  }
  else {
    $ca_allowed_values = $_ca_allowed_values

    file { $ca_cert_dir:
      ensure  => directory,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      purge   => true,
      recurse => true,
    }

    $ca_allowed.each |$filebeat_site, $ca_cert_path| {
      $ca_cert_string = hiera("ca_cert_${filebeat_site}", undef)
      if ($ca_cert_string != undef) {
        file { $ca_cert_path:
          ensure  => file,
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          content => $ca_cert_string,
          notify  => Service['logstash'],
        }
      }
      else {
        fail("ca_cert_string was undef for allowed CA site ${filebeat_site}; provide a valid TLS cert for ca_cert_${filebeat_site} key in Hiera")
      }
    }
  }
}
