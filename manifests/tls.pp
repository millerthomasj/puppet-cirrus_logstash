class cirrus_logstash::tls
{
  user { 'logstash':
    ensure => present,
    groups => 'puppet',
  }
}
