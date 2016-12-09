# Class cirrus_logstash::params
#
# Configure logstash basic parameters
#

class cirrus_logstash::params ()
{
  $logstash_manage_repo = false
  $logstash_tls_enable = true
  $logstash_tls_dir = '/var/lib/logstash/ssl'
  $logstash_allow_days = 1

  $syslog_port = '5000'
  $filebeat_port = '5044'

  $cross_site_enabled = false
  $output_stdout = false

  $openstack_allow_debug = false
  $syslog_allow_debug = false
  $elastic_allow_debug = false

  $logstash_allow_from_beats_sites = [ $::cirrus_site_iteration ]
  $beats_allow_to_logstash_sites = [ $::cirrus_site_iteration ]
}
