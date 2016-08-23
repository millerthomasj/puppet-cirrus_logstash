class cirrus_logstash::service
{
  exec { 'start_logstash':
    command =>'/usr/sbin/service logstash start',
    require => [ Class['logstash'] ],
    onlyif  => '/usr/sbin/service logstash status; test $? -ne 0',
  }

  exec { 'reload_logstash':
    command     => '/usr/sbin/service logstash reload',
    refreshonly => true,
    require     => Exec['start_logstash'],
    onlyif      => [ '/usr/sbin/service logstash status' ],
  }

  File_concat <| tag == "LS_CONFIG_${::fqdn}" |> ~> Exec['reload_logstash']
  File <| tag == 'logstash_config' |> ~> Exec['reload_logstash']
}
