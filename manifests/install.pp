class cirrus_logstash::install (
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb',
)
{
  class { 'logstash':
    package_url => $logstash_package_url,
    java_install => true,
  }

  logstash::plugin { 'logstash-input-beats': }

  include cirrus_logstash::config
}
