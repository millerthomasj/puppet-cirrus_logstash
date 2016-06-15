class cirrus_logstash::config
{
  $filter_dir = "${logstash::params::installpath}/logstash_filters"
  $filter_name = "openstack-filters.conf"

  vcsrepo { $filter_dir:
    ensure     => latest,
    provider   => git,
    source     => $cirrus_logstash::openstack_filters_repo,
    revision   => 'master',
  }

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

  logstash::configfile { 'filter_openstack':
    source => "file:///${filter_dir}/filters/${filter_name}",
    order  => 30,
    require => Vcsrepo[$filter_dir],
  }

  logstash::configfile { 'output_es':
    template => "cirrus_logstash/output-es.conf.erb",
    order   => 90,
  }
}
