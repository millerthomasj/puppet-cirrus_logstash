class cirrus_logstash::filters
{
  vcsrepo { $openstack_filters_dir:
    ensure     => present,
    provider   => git,
    source     => $cirrus_logstash::openstack_filters_repo,
    revision   => $cirrus_logstash::openstack_filters_commit,
  }

  if ! ( $openstack_filters_allow_debug ) {
    exec { 'allow_debug_messages':
      cwd         => "${openstack_filters_dir}/filters",
      environment => "HOME=/root",
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command     => "sed -i \"/DEBUG/,/^\s.}$/d" ${openstack_filters_dir}/filters/openstack-filters.conf",
      require     => Vcsrepo[$openstack_filters_dir], 
    }
  }
}
