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
# [* $logstash_tls_dir *]
#   If tls is enabled, this directory will manage all certificates.
#
# [* $logstash_allow_days *]
#   Drop all messages that are older than N days.
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
#   This value should be the DNS names of client nodes in a cross site elasticsearch cluster as an array:
#   [ "dnvrco02-logstash-001.os.cloud.twc.net:9200", "dnvrc02-logstash-002.os.cloud.twc.net:9200" ]
#
# === Hiera variables
#
# [* cirrus_logstash::openstack_allow_debug *]
#   Set this value to true if we do not want to drop DEBUG tagged messages through logstash openstack filters.
#
# [* cirrus_logstash::syslog_allow_debug *]
#   Set this value to true if we do not want to drop DEBUG tagged messages through logstash syslog filters.
#
# [* cirrus_logstash::elastic_allow_debug *]
#   Set this value to true if we do not want to drop DEBUG tagged messages through logstash elastic filters.
#
# [* logstash_allow_from_beats_sites *]
#  This array should contain an element for each cirrus_site_iteration from which you want Logstash to
#  authenticate Beats clients (e.g. Filebeat) and accept their messages. Since Beats clients must mutually
#  authenticate Logstash servers, the $beats_allow_to_logstash_sites array must also contain an element
#  matching the cirrus_site_iteration for each cluster of Logstash servers where Beats messages can be sent.
#  Defaults to allowing Beats-to-Logstash comms within the same cirrus_site_iteration.
#

class cirrus_logstash (
  $logstash_manage_repo               = $cirrus_logstash::params::logstash_manage_repo,
  $logstash_tls_enable                = $cirrus_logstash::params::logstash_tls_enable,
  $logstash_tls_dir                   = $cirrus_logstash::params::logstash_tls_dir,
  $logstash_allow_days                = $cirrus_logstash::params::logstash_allow_days,
  $syslog_port                        = $cirrus_logstash::params::syslog_port,
  $filebeat_port                      = $cirrus_logstash::params::filebeat_port,
  $cross_site_enabled                 = $cirrus_logstash::params::cross_site_enabled,
  $cross_site_elasticsearch           = [],
  $output_stdout                      = $cirrus_logstash::params::output_stdout,
  $openstack_allow_debug              = $cirrus_logstash::params::openstack_allow_debug,
  $syslog_allow_debug                 = $cirrus_logstash::params::syslog_allow_debug,
  $elastic_allow_debug                = $cirrus_logstash::params::elastic_allow_debug,
  $logstash_allow_from_beats_sites    = hiera_array('logstash_allow_from_beats_sites', $cirrus_logstash::params::logstash_allow_from_beats_sites),
) inherits cirrus_logstash::params
{
  include ::cirrus::repo::logstash

  if ( $cross_site_enabled ) {
    if ( $cross_site_elasticsearch == [] ) {
      fail('The cross_site_elasticsearch variable must be set with a valid array of hostnames.')
    }
  }

  class { '::logstash':
    manage_repo       => $logstash_manage_repo,
    java_install      => true,
    restart_on_change => false,
  }

  include ::cirrus_logstash::service

  logstash::plugin { 'logstash-input-beats': }

  if ( $logstash_tls_enable ) {
    include ::cirrus_logstash::tls
  }

  include ::cirrus_logstash::config
}
