# == Class: nginx
#
# This module ensures that Nginx is properly installed and configured to work
# with 3scale's proxy.
#
# === Examples
#
#  class { nginx: }
#
#  or
#
#  include nginx
#
# === Authors
#
# Rhommel Lamas <roml@rhommell.com>
#
# === Copyright
#
# Copyright 2013 Rhommel Lamas.
class nginx (
  $provider_id       = "${nginx::params::provider_id}",
  $openresty_version = "${nginx::params::openresty_version}",
  $prefix            = "${nginx::params::prefix}",
  $openresty_path    = "${nginx::params::openresty_path}"
) inherits nginx::params {

  include nginx::dependencies
  include nginx::install
  include nginx::service

  File{
    owner   => 'nginx',
    group   => 'nginx',
    mode    => '0644',
  }

  file {
    "${openresty_path}/nginx/conf/nginx.conf":
      ensure  => 'present',
      source  => "puppet:///qualify/configuration/qsp.conf",
      require => [ User['nginx'], Exec['make-install'] ],
      notify  => Service['nginx']
  }

  file {
    "${openresty_path}/nginx/conf/qsp":
      ensure  => directory,
      recurse => true,
      purge   => true,
      source  => 'puppet:///qualify/configuration/qsp/',
  }

  file {
    '/etc/init.d/nginx':
      ensure  => 'present',
      mode    => '0755',
      content => template('nginx/nginx-init.erb'),
      notify  => Service['nginx']
  }
}
