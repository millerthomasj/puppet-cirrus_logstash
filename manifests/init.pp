# == Class cirrus_logstash
#
# Includes the logstash class from the elasticsearch/logstash module.
#
# === Variables
#
# [* $logstash_manage_repo *]
#   We install from blobmirror so this will always be false.
#
# [* $logstash_tls_enable *]
#   Enable tls for all filebeat -> logstash communications.
#
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
# === Hiera variables
#
# [* cirrus_logstash::openstack_filters_allow_debug *]
#   Set this value to true if we do not want to drop DEBUG tagged messages through logstash openstack filters.
#
# [* cirrus_logstash::syslog_filters_allow_debug *]
#   Set this value to true if we do not want to drop DEBUG tagged messages through logstash syslog filters.
#

class cirrus_logstash (
  $logstash_manage_repo = $cirrus_logstash::params::logstash_manage_repo,
  $logstash_tls_enable = $cirrus_logstash::params::logstash_tls_enable,
  $syslog_port = $cirrus_logstash::params::syslog_port,
  $filebeat_port = $cirrus_logstash::params::filebeat_port,
  $cross_site_enabled = $cirrus_logstash::params::cross_site_enabled,
  $cross_site_elasticsearch = undef,
  $syslog_filters_allow_debug = $cirrus_logstash::params::syslog_filters_allow_debug,
) inherits cirrus_logstash::params
{
  include ::cirrus::repo::logstash

  if ( $cross_site_enabled ) {
    if ( $cross_site_elasticsearch == undef ) {
      fail('The cross_site_elasticsearch variable must be set with a valid hostname or IP.')
    }
  }

  class { '::logstash':
    manage_repo  => $logstash_manage_repo,
    java_install => true,
  }

  logstash::plugin { 'logstash-input-beats': }

  if ( $logstash_tls_enable ) {
    include ::cirrus_logstash::tls
  }

  include ::cirrus_logstash::config
}
