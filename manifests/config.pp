class cirrus_logstash::config
{
  logstash::configfile { 'input_syslog':
    template => "cirrus_logstash/input-syslog.conf.erb",
    order  => 2,
  }

  logstash::configfile { 'input_filebeat':
    template => "cirrus_logstash/input-filebeat.conf.erb",
    order  => 3,
  }

  logstash::configfile { 'filter_syslog':
    source => "puppet:///modules/cirrus_logstash/filter-syslog.conf",
    order  => 20,
  }

#  logstash::configfile { 'filter_openstack':
#    source => "file:///${cirrus_logstash::openstack_filters_dir}/filters/openstack-filters.conf",
#    order  => 30,
#  }

  logstash::configfile { 'output_es':
    template => "cirrus_logstash/output-es.conf.erb",
    order   => 90,
  }
}
