# == Class cirrus_logstash
#
# Includes the logstash class from the elasticsearch/logstash module.
#
# === Variables
#
# [*$logstash_package_url*]
#   This is what controls the version of logstash to install, this version must be compatible with the
#   version of elasticsearch that is running.
#
# === Hiera variables
# [* cirrus_logstash::syslog_port *]
#   The port that all logstash nodes should accept syslog traffic on.
#
# [* cirrus_logstash::filebeat_port *]
#   The port that all logstash nodes should accept beats traffic on.
#
# [* cirrus_logstash::cross_site_enabled *]
#   This will tell this module whether or not to ship logs between the NCE and NCW sites (true or false).
#
# [* cirrus_logstash::cross_site_elasticsearch *]
#   This value should be either the DNS name or the IP address of a client node in a cross site elasticsearch cluster.
#

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
