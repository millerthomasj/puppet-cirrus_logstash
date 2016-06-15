class cirrus_logstash::params ()
{
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb'

  $syslog_port = '5000'
  $filebeat_port = '5044'

  $cross_site_enabled = false

  $openstack_filters_repo = 'https://git.openstack.org/openstack-infra/logstash-filters'
}
