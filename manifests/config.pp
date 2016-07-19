class cirrus_logstash::config
{
  logstash::configfile { 'input_syslog':
    template => 'cirrus_logstash/input-syslog.conf.erb',
    order    => 2,
  }

  logstash::configfile { 'input_filebeat':
    template => 'cirrus_logstash/input-filebeat.conf.erb',
    order    => 3,
  }

  logstash::configfile { 'filter_syslog':
    template => 'cirrus_logstash/filter-syslog.conf.erb',
    order    => 20,
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

  logstash::configfile { 'filter_ceph_format':
    template => 'cirrus_logstash/filter-ceph-format.conf.erb',
    order    => 60,
  }

  logstash::configfile { 'filter_oslo_format':
    template => 'cirrus_logstash/filter-oslo-format.conf.erb',
    order    => 61,
  }

  logstash::configfile { 'filter_libvirt':
    template => 'cirrus_logstash/filter-libvirt.conf.erb',
    order    => 62,
  }

  logstash::configfile { 'output_es':
    template => 'cirrus_logstash/output-es.conf.erb',
    order    => 90,
  }
}
