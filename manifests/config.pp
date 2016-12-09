# Class cirrus_logstash::config
#
# Configure logstash
#

class cirrus_logstash::config (
  $fqdn                         = $::fqdn,
  $allow_days                   = $cirrus_logstash::logstash_allow_days,
  $syslog_port                  = $cirrus_logstash::syslog_port,
  $filebeat_port                = $cirrus_logstash::filebeat_port,
  $tls_enable                   = $cirrus_logstash::logstash_tls_enable,
  $tls_dir                      = $cirrus_logstash::logstash_tls_dir,
  $ca_allowed_values            = $cirrus_logstash::tls::ca_allowed_values,
  $openstack_allow_debug        = $cirrus_logstash::openstack_allow_debug,
  $syslog_allow_debug           = $cirrus_logstash::syslog_allow_debug,
  $elastic_allow_debug          = $cirrus_logstash::elastic_allow_debug,
  $output_stdout                = $cirrus_logstash::output_stdout,
  $cross_site_enabled           = $cirrus_logstash::cross_site_enabled,
  $cross_site_elasticsearch     = $cirrus_logstash::cross_site_elasticsearch,
)
{
  logstash::patternfile { 'horizon_apache_patterns':
    source   => 'puppet:///modules/cirrus_logstash/horizon_apache_patterns',
    filename => 'horizon_apache_patterns',
  }

  logstash::configfile { 'input_syslog':
    content => template('cirrus_logstash/input-syslog.conf.erb'),
    order   => 2,
  }

  logstash::configfile { 'input_filebeat':
    content => template('cirrus_logstash/input-filebeat.conf.erb'),
    order   => 3,
  }

  logstash::configfile { 'filter_syslog':
    content => template('cirrus_logstash/filter-syslog.conf.erb'),
    order   => 20,
  }

  logstash::configfile { 'filter_elasticsearch':
    content => template('cirrus_logstash/filter-elasticsearch.conf.erb'),
    order   => 21,
  }

  logstash::configfile { 'filter_cinder':
    source => 'puppet:///modules/cirrus_logstash/filter-cinder.conf',
    order  => 30,
  }

  logstash::configfile { 'filter_compute':
    source => 'puppet:///modules/cirrus_logstash/filter-compute.conf',
    order  => 31,
  }

  logstash::configfile { 'filter_control':
    source => 'puppet:///modules/cirrus_logstash/filter-control.conf',
    order  => 32,
  }

  logstash::configfile { 'filter_designate':
    source => 'puppet:///modules/cirrus_logstash/filter-designate.conf',
    order  => 33,
  }

  logstash::configfile { 'filter_glance':
    source => 'puppet:///modules/cirrus_logstash/filter-glance.conf',
    order  => 34,
  }

  logstash::configfile { 'filter_heat':
    source => 'puppet:///modules/cirrus_logstash/filter-heat.conf',
    order  => 35,
  }

  logstash::configfile { 'filter_keystone':
    source => 'puppet:///modules/cirrus_logstash/filter-keystone.conf',
    order  => 36,
  }

  logstash::configfile { 'filter_neutron':
    source => 'puppet:///modules/cirrus_logstash/filter-neutron.conf',
    order  => 37,
  }

  logstash::configfile { 'filter_nova':
    source => 'puppet:///modules/cirrus_logstash/filter-nova.conf',
    order  => 38,
  }

  logstash::configfile { 'filter_trove':
    source => 'puppet:///modules/cirrus_logstash/filter-trove.conf',
    order  => 39,
  }

  logstash::configfile { 'filter_apache':
    source => 'puppet:///modules/cirrus_logstash/filter-apache.conf',
    order  => 40,
  }

  logstash::configfile { 'filter_horizon':
    source => 'puppet:///modules/cirrus_logstash/filter-horizon.conf',
    order  => 41,
  }

  logstash::configfile { 'filter_apache_format':
    content => template('cirrus_logstash/filter-apache-format.conf.erb'),
    order   => 60,
  }

  logstash::configfile { 'filter_ceph_format':
    content => template('cirrus_logstash/filter-ceph-format.conf.erb'),
    order   => 61,
  }

  logstash::configfile { 'filter_oslo_format':
    content => template('cirrus_logstash/filter-oslo-format.conf.erb'),
    order   => 62,
  }

  logstash::configfile { 'filter_libvirt':
    content => template('cirrus_logstash/filter-libvirt.conf.erb'),
    order   => 63,
  }

  logstash::configfile { 'filter_uwsgi_format':
    content => template('cirrus_logstash/filter-uwsgi-format.conf.erb'),
    order   => 64,
  }

  logstash::configfile { 'filter_kafka_format':
    content => template('cirrus_logstash/filter-kafka-format.conf.erb'),
    order   => 65,
  }

  logstash::configfile { 'filter_monasca_format':
    content => template('cirrus_logstash/filter-monasca-format.conf.erb'),
    order   => 66,
  }

  logstash::configfile { 'filter_storm_format':
    content => template('cirrus_logstash/filter-storm-format.conf.erb'),
    order   => 67,
  }

  logstash::configfile { 'filter_swift_format':
    content => template('cirrus_logstash/filter-swift-format.conf.erb'),
    order   => 68,
  }

  $allow_seconds = $allow_days * 60 * 60 * 24

  logstash::configfile { 'filter_datetime':
    content => template('cirrus_logstash/filter-datetime.conf.erb'),
    order   => 80,
  }

  logstash::configfile { 'output_es':
    content => template('cirrus_logstash/output-es.conf.erb'),
    order   => 90,
  }
}
