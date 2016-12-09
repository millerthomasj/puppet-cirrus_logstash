# Class cirrus_logstash::service
#
# Configure logstash service for reload
#

class cirrus_logstash::service
{
  exec { 'start_logstash':
    command =>'/usr/sbin/service logstash start',
    require => [ Class['logstash'] ],
    onlyif  => '/usr/sbin/service logstash status; test $? -ne 0',
  }

  exec { 'reload_logstash':
    command     => '/usr/sbin/service logstash restart',
    refreshonly => true,
    timeout     => '120',
    tries       => '3',
    require     => Exec['start_logstash'],
    onlyif      => [ '/usr/sbin/service logstash status' ],
  }

  File_concat <| tag == "LS_CONFIG_${::fqdn}" |> ~> Exec['reload_logstash']
  File <| tag == 'logstash_config' |> ~> Exec['reload_logstash']
}
