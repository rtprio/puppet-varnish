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
# == Class: varnish
#
# Configure Varnish
#
class varnish ($config = {}) {
  anchor{'varnish::begin': } ->

  class { 'varnish::package':
    package_manage => pick($config['package_manage'], hiera('varnish::config::package_manage')),
    package_name   => pick($config['package_name'], hiera('varnish::config::package_name')),
    package_ensure => pick($config['package_ensure'], hiera('varnish::config::package_ensure')),
  }

  create_resources('class', {
    'varnish::config' => deep_merge({
      require => Class['varnish::package'],
      before  => Class['varnish::service'],
      notify  => Class['varnish::service'],
    }, $config)
  })

  class { 'varnish::service':
    service_manage => pick($config['service_manage'], hiera('varnish::config::service_manage')),
    service_enable => pick($config['service_enable'], hiera('varnish::config::service_enable')),
    service_ensure => pick($config['service_ensure'], hiera('varnish::config::service_ensure')),
  } ->

  anchor{ 'varnish::end': }
}
