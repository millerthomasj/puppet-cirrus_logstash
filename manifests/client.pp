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
#   Array of hashes, where each hash sets parameters for a Filebeat Prospector. A Prospector is
#   a configuration element used by Filebeat to determine a set of paths from which to harvest
#   logs. For every path specified in a Prospector, a Harvester process is started to read that
#   log file (similar to "tail -f", but the default is to read the whole file and then follow as
#   necessary).
#   We use one Prospector per path (Harvester) to allow for greater granularity & flexibility
#   further down the ELK data pipeline. Filebeat ONLY sets metadata at the Prospector (vice
#   Harvester) level.
#   In Hiera, specify filebeat_prospectors as an array of hashes. We merge the arrays from
#   the entier hierarchy, then create a Prospector per hash. At a minimum, each hash should
#   specify "paths" (array) and "doc_type" (string). Globs "*" are supported in "paths", but all
#   files matching the glob will be treated the same by Filebeat --> ELK. DO NOT use globs for
#   log files with even slightly different formats. HERE BE DRAGONS...
#   The "doc_type" is used for filtering in Logstash, so the "doc_type" you reference should
#   exist in a Logstash filter template.
#   !! If you want to add custom metadata to all events from a given log file, add the metadata
#   within a "fields" hash nested under the corresponding filebeat_prospectors hash. !!
#

class cirrus_logstash::client (
  $filebeat_prospectors = [],
  $filebeat_enabled   = false,
  $logstash_hosts     = ["${cirrus_site_iteration}-logstash-001.${domain}","${cirrus_site_iteration}-logstash-002.${domain}"],
  $prospectors_system = hiera_array('cirrus_logstash::client::system_log_paths', ['/var/log/auth.log', '/var/log/syslog'] ),
)
{
  if $filebeat_enabled {
    class { 'filebeat':
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
      #Set manage_repo to 'false' as we mirror the 'beats' repo with blobmaster & blobmirror
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
    #Set $filebeat_prospectors to an array of hashes in Hiera, where each hash is input to filebeat::prospector
    validate_array($filebeat_prospectors)
    #Create a Filebeat Prospector for each hash in filebeat_prospectors array
    #This lets us specify the "type" for each monitored file, which is useful in Logstash filtering
    create_resources('filebeat::prospector', $filebeat_prospectors, $filebeat_prospectors_defaults)
    ###

  }
}
