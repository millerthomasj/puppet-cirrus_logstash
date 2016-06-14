class cirrus_logstash (
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb',
  $syslog_port = $cirrus_logstash::params::syslog_port,
  $filebeat_port = $cirrus_logstash::params::filebeat_port,
  $cross_site_enabled = $cirrus_logstash::params::cross_site_enabled,
  $cross_site_elasticsearch = undef,
) inherits cirrus_logstash::params
{
  if ( $cross_site_enabled ) {
    if ( $cross_site_elasticsearch == undef ) {
      fail("The cross_site_elasticsearch variable must be set with a valid hostname or IP.")
    }
  }

  class { 'logstash':
    package_url => $logstash_package_url,
    java_install => true,
  }

  logstash::plugin { 'logstash-input-beats': }

  include cirrus_logstash::config
}
