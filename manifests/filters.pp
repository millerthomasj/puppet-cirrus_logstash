class cirrus_logstash::filters
{

  # Create a link then manage the repo appropriately?
  #
  if ! ( $cirrus_logstash::openstack_filters_allow_debug ) {
    vcsrepo { $cirrus_logstash::openstack_filters_dir:
      ensure     => present,
      provider   => git,
      source     => $cirrus_logstash::openstack_filters_repo,
      revision   => $cirrus_logstash::openstack_filters_commit,
    }

    exec { 'allow_debug_messages':
      cwd         => "${cirrus_logstash::openstack_filters_dir}/filters",
      environment => "HOME=/root",
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command     => "sed -i \"/== \\\"DEBUG\\\"/,/^\s.}$/d\" ${cirrus_logstash::openstack_filters_dir}/filters/openstack-filters.conf",
      require     => Vcsrepo[$cirrus_logstash::openstack_filters_dir], 
    }
  }
  else {
    vcsrepo { $cirrus_logstash::openstack_filters_dir:
      ensure     => latest,
      provider   => git,
      source     => $cirrus_logstash::openstack_filters_repo,
      revision   => $cirrus_logstash::openstack_filters_commit,
    }
  }
}
