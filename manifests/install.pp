# == Class: nginx::install
#
# This module ensures that Nginx is properly installed, with openresty and Lua.
#
# === Examples
#
#  class { 'nginx::install': }
#
#  or
#
#  include nginx::install
#
# === Authors
#
# Rhommel Lamas <roml@rhommell.com>
#
# === Copyright
#
# Copyright 2013 Rhommel Lamas.
class nginx::install (
  $provider_id       = "${nginx::params::provider_id}",
  $openresty_version = "${nginx::params::openresty_version}",
  $prefix            = "${nginx::params::prefix}",
  $openresty_path    = "${nginx::params::openresty_path}",
  $tarball_path      = "${nginx::params::tarball_path}",
  ) inherits nginx::params {

  File {
    owner => 'nginx',
    group => 'nginx',
  }

  # Ensures needed directories exist
  if ! defined(File["${prefix}"]) {
    file {
      "${prefix}":
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }
  }

  # Ensure User/group Nginx exists as a system user
  group { 'nginx': gid  =>  '1200' }

  user {
    'nginx':
      ensure     => 'present',
      comment    => 'Nginx system user',
      uid        => '1200',
      gid        => '1200',
      shell      => '/bin/false',
      groups     => ['nginx', 'ssl-cert'],
      system     => true,
  }

  exec { "openssl dhparam -out dhparam.pem 2048":
    path    => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
    cwd     => '/etc/ssl/certs',
    creates => '/etc/ssl/certs/dhparam.pem',
    require => Package['openssl']
  }

  # Ensure we have the needed Nginx and dependencies packages
  $tarball = "$prefix/ngx_openresty-${openresty_version}.tar.gz"
  exec { "create $tarball":
      command => "/usr/bin/wget -O '$tarball' '$tarball_path/ngx_openresty-${openresty_version}.tar.gz'",
      creates => $tarball,
      alias   => 'nginx-source-tgz',
      before  => Exec['untar-nginx-source']
  }

  # Untar the files.
  exec {
    "tar xzf ngx_openresty-${openresty_version}.tar.gz":
      path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ],
      cwd       => "${prefix}",
      creates   => "${prefix}/ngx_openresty-${openresty_version}",
      alias     => 'untar-nginx-source',
      subscribe => Exec['nginx-source-tgz']
  }

  # Configure nginx with needed options --with-luajit is required.
  exec {
    "/bin/ls | ./configure --prefix=${openresty_path} --with-luajit --with-http_iconv_module --with-ipv6 --with-pcre-jit -j2 && touch ${prefix}/ngx_openresty-${openresty_version}/.config":
      path    => [ '/bin/', '/sbin/' ,'/usr/bin/','/usr/sbin/' ],
      cwd     => "${prefix}/ngx_openresty-${openresty_version}",
      require => [ Package['libreadline-dev'], Package['libncurses5-dev'], Package['libpcre3'], Package['libpcre3-dev'], Package['libssl-dev'], Package['perl'], Exec['untar-nginx-source'] ],
      creates => "${prefix}/ngx_openresty-${openresty_version}/.config",
      alias   => 'configure-nginx',
      before  => Exec['make-install']
  }

  exec {
    'make && make install':
      path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      cwd     => "/usr/src/ngx_openresty-${openresty_version}",
      alias   => 'make-install',
      creates => '/opt/openresty/nginx/sbin/nginx',
      require => Exec['configure-nginx']
  }
}
