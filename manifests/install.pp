class cirrus_logstash::install (
  $logstash_package_url = 'https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.2-1_all.deb',
  $syslog_port = $cirrus_logstash::install::syslog_port,
  $filebeat_port = $cirrus_logstash::install::filebeat_port,
)
{
  class { 'logstash':
    package_url => $logstash_package_url,
    java_install => true,
  }

  logstash::plugin { 'logstash-input-beats': }

  class { 'cirrus_logstash::config':
    syslog_port   => $syslog_port,
    filebeat_port => $filebeat_port,
  }
}
