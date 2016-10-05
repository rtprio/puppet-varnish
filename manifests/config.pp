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
# == Class varnish::config
#
# This class is called from varnish
#
class varnish::config(
  $package_name         = undef,
  $package_ensure       = undef,
  $package_manage       = undef,

  $service_ensure       = undef,
  $service_enable       = undef,
  $service_manage       = undef,

  $vcl_config_file      = undef,
  $secret_file          = undef,
  $secret_pass          = undef,
  $params_path          = undef,
  $params_template      = undef,

  $listen_address       = undef,
  $listen_port          = undef,
  $admin_listen_address = undef,
  $admin_listen_port    = undef,

  $storage_spec         = undef,

  $vcl_content          = undef,
  $vcl_template         = undef,
  $vcl_source           = undef,

  $runtime_user         = undef,
  $default_ttl          = undef,

  $parameters           = {},
  $runtime_options      = [],
) {
  assert_private()

  validate_bool($package_manage)
  validate_bool($service_manage)

  validate_absolute_path($vcl_config_file)
  validate_absolute_path($secret_file)
  validate_absolute_path($params_path)
  validate_re($params_template, '\.erb$',
              "Invalid params_template parameter (${params_template}); expected it to end with '.erb'")

  validate_string($runtime_user)

  validate_ipv4_address($listen_address)
  validate_integer($listen_port, 65535, 1024)

  validate_ipv4_address($admin_listen_address)
  validate_integer($admin_listen_port, 65535, 1024)

  validate_storage_spec($storage_spec)
  $storage_specification = normalize_storage_spec($storage_spec)

  validate_integer($default_ttl)

  validate_hash($parameters)
  validate_array($runtime_options)

  if ($secret_pass) {
    file { $secret_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $secret_pass,
    }
  } else {
    file { $secret_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      replace => false,
      content => inline_template("<%- require 'securerandom' -%><%= SecureRandom.uuid %>"),
    }
  }

  if ( ($vcl_content and $vcl_template) or ($vcl_content and $vcl_source) or ($vcl_template and $vcl_source)) {
    fail('vcl_content, vcl_template and vcl_source are all mutually exclusive - you must choose one')
  } elsif ($vcl_content) {
    validate_string($vcl_content)
    $vcl_content_config = { content => $vcl_content }
  } elsif ($vcl_template) {
    validate_string($vcl_template)
    validate_re($vcl_template, '\.erb$', "Invalid vcl_template parameter (${vcl_template}); expected it to end with '.erb'")
    $vcl_content_config = { content => template($vcl_template) }
  } elsif ($vcl_source) {
    validate_re($vcl_source, '^puppet:///', "Invalid vcl_source parameter (${vcl_source}); expected it to start with 'puppet:///'")
    $vcl_content_config = { source => $vcl_source }
  } else {
    # if we're here, we're going with a default setup, so use our default.vcl - BUT,
    # only setup a new one and don't replace an existing one
    $vcl_content_config = { source => 'puppet:///modules/varnish/default.vcl', replace => false }
  }

  file { $params_path:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($params_template),
  }

  create_resources('file', { "${vcl_config_file}" => $vcl_content_config }, {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['varnish'],
  })
}
