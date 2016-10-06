# Copyright (c) 2016 Finalsite
# Copyright (c) 2016 Carl P. Corliss <carl.corliss@finalsite.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
# AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.
#
# Class: varnish::service
# ===========================
#
# Private class used by varnish class to setup varnish service.
#
# Authors
# -------
#
# Carl P. Corliss <carl.corliss@finalsite.com>
#
class varnish::service(
  $service_manage   = $::varnish::config::service_manage,
  $service_ensure   = $::varnish::config::service_ensure,
  $service_enable   = $::varnish::config::service_enable
) {
  assert_private()

  validate_bool($service_manage)

  if ($service_manage) {
    if (!is_bool($service_ensure)) {
      validate_re($service_ensure, '^(?i:true|running|false|stopped)$',
        "Invalid service_ensure '${service_ensure}'; expected a boolean value, or one of running, stopped")
    }

    if (!is_bool($service_enable)) {
      validate_re($service_enable, '^(?i:true|false|manual|mask)$',
        "Invalid service_enable '${service_enable}'; expected a boolean value, or one of manual, mask")
    }

    file { '/etc/systemd/system/varnish.service':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('varnish/varnish.service.erb'),
    }

    exec { 'systemctl_reload_varnish_service':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      subscribe   => File['/etc/systemd/system/varnish.service'],
      notify      => Service['varnish'],
      before      => Service['varnish']
    }

    service {'varnish':
      ensure    => pick($service_ensure, 'running'),
      enable    => pick($service_enable, true),
      subscribe => [
        File[$::varnish::config::params_path],
        File[$::varnish::config::vcl_config_file]
      ],
      require   => File['/etc/systemd/system/varnish.service']
    }

    file { '/etc/sysconfig/varnishncsa':
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('varnish/varnishncsa.sysconfig.erb')
    }

    file { '/etc/systemd/system/varnishncsa.service':
      owner  => root,
      group  => root,
      mode   => '0644',
      source => 'puppet:///modules/varnish/varnishncsa.service'
    }

    file { '/var/log/varnish':
      ensure => 'directory',
      owner  => 'varnishlog',
      group  => 'varnish',
      mode   => '1775',
    }

    exec { 'systemctl_reload_varnishncsa_service':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
      subscribe   => File['/etc/systemd/system/varnishncsa.service'],
      notify      => Service['varnishncsa'],
      before      => Service['varnishncsa']
    }

    service { 'varnishncsa':
      ensure    => pick($service_ensure, 'running'),
      enable    => pick($service_enable, true),
      subscribe => File['/etc/sysconfig/varnishncsa'],
      require   => [
        File['/var/log/varnish'],
        File['/etc/systemd/system/varnishncsa.service'],
      ],
    }
  }
}
