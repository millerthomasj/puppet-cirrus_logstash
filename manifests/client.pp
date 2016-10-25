# == Class cirrus_logstash::client
#
# Includes the filebeat class from the pcfens/puppet-filebeat module.
#
# === Hiera variables
#
# [* cirrus_logstash::client::filebeat_enabled *]
#   Set this to true to enable install of Beats (filebeat, topbeat, factbeat) on a node.
#   Beats are lightweight shippers from Elastic open-source that use a common libbeat library
#   to send events to Logstash --> Elasticsearch.
#
# [* cirrus_logstash::client::logstash_hosts *]
#   Array of Logstash server '<hostname>:<port>' destinations to which Beats will ship events.
#
# [* cirrus_logstash::client::filebeat_prospectors *]
#   A hash of hashes, where each nested hash sets parameters for a Filebeat Prospector.
#   A Prospector is a configuration element used by Filebeat to determine a set of paths from
#   which to harvest logs. For every path specified in a Prospector, a Harvester process is
#   started to read that log file (similar to "tail -f", but the default is to read the whole
#   file and then follow as necessary).
#
#   Since Filebeat ONLY sets metadata at the Prospector (vice Harvester) level, we use one
#   Prospector per path (Harvester) to allow for greater granularity & flexibility further down
#   the ELK data pipeline.
#
#   In Hiera, specify filebeat_prospectors as a (primary) hash of (Prospector) hashes. We merge
#   the hashes from the entire hierarchy, then create a Prospector per nested hash. At a minimum,
#   each Prospector hash should specify "paths" (array) and "fields" (hash).
#   (** see example Hiera at end of comments **)
#
#   Globs "*" are supported in "paths", but all files matching the glob will be treated the same
#   by Filebeat -> Logstash -> Elasticsearch -> Kibana. 
#   DO NOT use globs for log files with even slightly different formats. HERE BE DRAGONS...
#
#   Logstash uses keys:values from the "fields" hash for filtering & converting input log messages
#   to a useful, consistent document structure in Elasticsearch. In particular, Logstash filters
#   on "tags"; include a "tags" key within the "fields" hash, where the value for the "tags" key
#   is an array of tags. Any other keys:values in the "fields" hash will become searchable fields
#   in Elasticsearch. This allows you to add custom metadata for all events from a given log file.
#
# [* $logstash_tls_enable *]
#   Enable tls for all filebeat -> logstash communications.
#
# [* beats_allow_to_logstash_sites *]
#   This array should contain an element for each cirrus_site_iteration for which you want Beats
#   clients (e.g. Filebeat) to authenticate Logstash hosts and send messages to them. Since Logstash
#   must mutually authenticate Beats clients, the $cirrus_logstash::logstash_allow_from_beats_sites
#   array must also contain an element matching the cirrus_site_iteration for your Beats clients.
#   Defaults to allowing Beats-to-Logstash TLS comms within the same cirrus_site_iteration.
#
# Example Hiera...
#   cirrus_logstash::client::filebeat_prospectors:
#     var_log_auth_log:
#     paths:
#       - /var/log/auth.log
#     fields:
#       tags:
#         - security
#         - auth
#         - syslog
#       my_custom_field: "testing filebeat's custom fields"
#

class cirrus_logstash::client (
  $filebeat_enabled                  = false,
  $filebeat_prospectors              = hiera_hash('filebeat_prospectors', {}),
  $filebeat_prospectors_ignore_older = '24h',
  $logstash_hosts                    = ["${::cirrus_site_iteration}-logstash-001.${::domain}","${::cirrus_site_iteration}-logstash-002.${::domain}"],
  $logstash_tls_enable               = $cirrus_logstash::params::logstash_tls_enable,
  $beats_allow_to_logstash_sites     = hiera_array('beats_allow_to_logstash_sites', $cirrus_logstash::params::beats_allow_to_logstash_sites),
) inherits cirrus_logstash::params
{
  if $filebeat_enabled {
    #Include the apt repo for 'beats', so clients can download the filebeat*.deb package
    include ::cirrus::repo::beats

    if $logstash_tls_enable {
      validate_array($beats_allow_to_logstash_sites)

      $ca_cert_dir = '/etc/filebeat/tls'
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

      # Find the intersection of $ca_options_keys with $beats_allow_to_logstash_sites.
      # Assume the intersection is the list of sites we actually want to allow.
      # Delete the intersection from the list of all options ( $ca_options_keys ), then delete
      # the keys for the remaining options to produce a hash with only the keys we want.
      # ... because Puppet DSL.

      $ca_intersection = intersection($ca_options_keys, $beats_allow_to_logstash_sites)
      $ca_disallowed = delete($ca_options_keys, $ca_intersection)
      $ca_allowed = delete($ca_options, $ca_disallowed)
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

        $ca_allowed.each |$logstash_site, $ca_cert_path| {
          $ca_cert_string = hiera("ca_cert_${logstash_site}", undef)
          if ($ca_cert_string != undef) {
            file { $ca_cert_path:
              ensure  => file,
              mode    => '0644',
              owner   => 'root',
              group   => 'root',
              content => $ca_cert_string,
              notify  => Service['filebeat'],
            }
          }
          else {
            fail("ca_cert_string was undef for allowed CA site ${logstash_site}; provide a valid TLS cert for ca_cert_${logstash_site} key in Hiera")
          }
        }
      }


      $logstash_config_output = {
                                  'logstash' => {
                                    'hosts' => $logstash_hosts,
                                    'loadbalance' => true,
                                    'tls' => {
                                      'certificate_authorities' => $ca_allowed_values,
                                      'certificate' => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
                                      'certificate_key' => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
                                    }
                                  }
                                }
    } else {
      $logstash_config_output = {
                                  'logstash' => {
                                    'hosts' => $logstash_hosts,
                                    'loadbalance' => true,
                                  }
                                }
    }

    class { '::filebeat':
      logging     => {
        'level'     => 'info',
        'to_files'  => true,
        'to_syslog' => false,
        'files'     => {
          'keepfiles' => 3,
          'name'      => 'filebeat.log',
          'path'      => '/var/log/beats',
        },
      },
      #Set manage_repo to 'false' as we mirror the 'beats' repo with blobmaster & blobmirror.
      manage_repo => false,
      outputs     => $logstash_config_output,
    }

    ### Here we create Prospectors in Filebeat; Prospectors determine how & which logs are monitored.
    #Defaults to use in create_resources for 'filebeat::prospector'.
    $filebeat_prospectors_defaults = {
      ensure            => 'present',
      exclude_files     => [],
      input_type        => 'log',
      fields            => {},
      fields_under_root => false,
      close_older       => '1h',
      ignore_older      => $filebeat_prospectors_ignore_older,
      doc_type          => 'cirrus_log',
      scan_frequency    => '10s',
      tail_files        => false,
      include_lines     => [],
      exclude_lines     => [],
      max_bytes         => 10485760,
      multiline         => {},
    }

    #Set $filebeat_prospectors to an array of hashes in Hiera.
    #Each hash is used as input to the filebeat::prospector define.
    validate_hash($filebeat_prospectors)
    create_resources('filebeat::prospector', $filebeat_prospectors, $filebeat_prospectors_defaults)

    Apt::Source['beats'] -> Package['filebeat']
  }
}
