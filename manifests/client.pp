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
#Exampe Hiera...
##cirrus_logstash::client::filebeat_prospectors:
##  var_log_auth_log:
##    paths:
##      - /var/log/auth.log
##    fields:
##      tags:
##        - security
##        - auth
##        - syslog
##      my_custom_field: "testing filebeat's custom fields"
##  var_log_syslog:
##   paths:
##      - /var/log/syslog
##    fields:
##      tags:
##        - syslog
##      my_other_custom_field: "another test of filebeat's custom fields"
#


class cirrus_logstash::client (
  $filebeat_enabled     = false,
  $filebeat_prospectors = hiera_hash('filebeat_prospectors', {}),
  $logstash_hosts       = ["${::cirrus_site_iteration}-logstash-001.${::domain}","${::cirrus_site_iteration}-logstash-002.${::domain}"],
)
{
  if $filebeat_enabled {
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
      outputs     => {
        'logstash' => {
          'hosts'       => $logstash_hosts,
          'loadbalance' => true,
        },
      },
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
    ###

  }
}
