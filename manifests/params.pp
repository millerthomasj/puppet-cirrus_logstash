class cirrus_logstash::params ()
{
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb'

  $syslog_port = '5000'
  $filebeat_port = '5044'

  $cross_site_enabled = false

  $openstack_filters_repo = 'https://git.openstack.org/openstack-infra/logstash-filters'
  $openstack_filters_commit = 'd33c95310dea7bfcf2d985f2dc80de54c0a9f118'
  $openstack_filters_dir = "/opt/logstash/logstash_filters"
  $openstack_filters_allow_debug = true
}
