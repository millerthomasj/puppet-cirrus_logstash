# == Class cirrus_logstash::client
#
# Includes the filebeat class from the pcfens/puppet-filebeat module.
#
# === Variables
#
# [*$enabled*]
#   Set this to true to enable install of Beats (filebeat, topbeat, factbeat) on a node.
#   Beats are lightweight shippers from Elastic open-source that use a common libbeat library
#   to send events to Logstash --> Elasticsearch.
#
#
# === Hiera variables
# [* cirrus_logstash::client::logstash_hosts *]
#   Array of Logstash server '<hostname>:<port>' destinations to which Beats will ship events.
#
# [* cirrus_logstash::client::system_log_paths *]
# !!When in doubt, just add the path of a syslog-compliant log to an array under ^ Hiera key.!!
#   Array of paths for Filebeat to monitor for operating system logs. Use a separate array for
#   operating system logs to maximize flexibility of ELK data pipeline.
#   This value will be looked up via a hiera_array call and will merge all values found in the
#   hierarchy. If no key is found, the default is ['/var/log/auth.log', '/var/log/syslog'].
#
# [* cirrus_logstash::client::openstack_log_paths *]
#   Array of paths for Filebeat to monitor for OpenStack service logs. Use a separate array for
#   OpenStack service logs to maximize flexibility of ELK data pipeline.
#   This value will be looked up via a hiera_array call and will merge all values found in the
#   hierarchy. If no key is found, the default is an empty array [].


class cirrus_logstash::client (
  $filebeat_enabled = false,
  $logstash_hosts = ["${cirrus_site_iteration}-logstash-001.${domain}","${cirrus_site_iteration}-logstash-002.${domain}"],
  $prospectors_system = hiera_array('cirrus_logstash::client::system_log_paths', ['/var/log/auth.log', '/var/log/syslog'] ),
  $prospectors_openstack_services = hiera_array('cirrus_logstash::client::openstack_log_paths', []),
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

    filebeat::prospector { 'system_logs':
      paths    => $prospectors_system,
      doc_type => 'system-logs-beat',
    }

    if $prospectors_openstack_services != [] {
      filebeat::prospector { 'openstack_service_logs':
        paths    => $prospectors_openstack_services,
        doc_type => 'openstack-svc-logs-beat',
      }
    }
  }
}
