# Class cirrus_logstash::tls
#
# Configure logstash security settings
#

class cirrus_logstash::tls (
  $ssl_dir = $cirrus_logstash::logstash_tls_dir,
)
{
  $cert_dir = "${ssl_dir}/certs"
  $private_dir = "${ssl_dir}/private_keys"

  File {
    owner   => 'logstash',
    group   => 'logstash',
  }

  file { $ssl_dir:
    ensure => directory,
    mode   => '0751',
  }

  file { $cert_dir:
    ensure  => directory,
    mode    => '0755',
    require => File[$ssl_dir],
  }

  file { "${cert_dir}/${::fqdn}.pem":
    ensure  => file,
    mode    => '0644',
    source  => "file:///var/lib/puppet/ssl/certs/${::fqdn}.pem",
    require => File[$cert_dir],
  }

  file { $private_dir:
    ensure  => directory,
    mode    => '0750',
    owner   => 'logstash',
    group   => 'logstash',
    require => File[$ssl_dir],
  }

  file { "${private_dir}/${::fqdn}.pem":
    ensure  => file,
    mode    => '0640',
    source  => "file:///var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    require => File[$private_dir],
  }

  $logstash_allow_from_beats_sites = $cirrus_logstash::logstash_allow_from_beats_sites
  validate_array($logstash_allow_from_beats_sites)


  $ca_options = { bfd01    => "${cert_dir}/ca-bfd01.pem",
                  bfd02    => "${cert_dir}/ca-bfd02.pem",
                  chrcnc01 => "${cert_dir}/ca-chrcnc01.pem",
                  chrcnc02 => "${cert_dir}/ca-chrcnc02.pem",
                  dev01    => "${cert_dir}/ca-dev01.pem",
                  dev02    => "${cert_dir}/ca-dev02.pem",
                  dnvrco01 => "${cert_dir}/ca-dnvrco01.pem",
                  dnvrco02 => "${cert_dir}/ca-dnvrco02.pem",
                  hrn01    => "${cert_dir}/ca-hrn01.pem",
                  hrn02    => "${cert_dir}/ca-hrn02.pem",
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
  }
  else {
    $ca_allowed_values = $_ca_allowed_values

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
