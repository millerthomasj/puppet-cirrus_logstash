class twc_logstash::config ()
{
  logstash::configfile { 'input_syslog':
    source => "puppet:///modules/twc-logstash/input-syslog.conf",
    order    => 2,
  }

  logstash::configfile { 'filter_apache':
    source => "puppet:///modules/twc-logstash/filter-syslog.conf",
    order  => 20,
  }

  logstash::configfile { 'output_es':
    source => "puppet:///modules/twc-logstash/output-es.conf",
    order   => 90,
  }
}
