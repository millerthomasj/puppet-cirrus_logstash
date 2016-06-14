class cirrus_logstash::install (
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb',
  $syslog_input_port = '5000',
  $filebeat_input_port = '5044',
)
{
  class { 'logstash':
    package_url => $logstash_package_url,
    java_install => true,
  }

  logstash::plugin { 'logstash-input-beats': }

  class { 'cirrus_logstash::config':
    syslog_port   => $syslog_input_port,
    filebeat_port => $filebeat_input_port,
  }
}
