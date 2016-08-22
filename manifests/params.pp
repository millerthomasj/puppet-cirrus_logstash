class cirrus_logstash::params ()
{
  $logstash_manage_repo = false
  $logstash_tls_enable = true
  $logstash_allow_days = 1

  $syslog_port = '5000'
  $filebeat_port = '5044'

  $cross_site_enabled = false
  $output_stdout = false

  $openstack_filters_allow_debug = false
  $syslog_filters_allow_debug = false
}
