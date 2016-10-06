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
require 'pathname'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-utils'
require 'fixtures/modules/module_data/lib/hiera/backend/module_data_backend.rb'

fixture_path = Pathname.new(File.expand_path(File.join(__FILE__, '..', 'fixtures')))

at_exit { RSpec::Puppet::Coverage.report! }

RSpec.configure do |c|
  c.mock_framework = :rspec
  c.module_path  = fixture_path.join('modules').to_s
  c.manifest_dir = fixture_path.join('manifests').to_s
  c.hiera_config = fixture_path.dirname.join('hiera', 'hiera.yaml').to_s
  c.default_facts = {
    kernel:                    'Linux',
    osfamily:                  'RedHat',
    operatingsystem:           'CentOS',
    operatingsystemmajrelease: 7,
    operatingsystemrelease:    '7.1.1503',
  }
end

def assert_valid_parameter(key, value, &block)
  assert_valid_config_param(
    'parameters',
    { key => value },
    %Q.^(DAEMON_OPTS="|\\s*)-p #{Shellwords.escape(key)}=#{Shellwords.escape(value)}\\b.,
    &block
  )
end

def assert_invalid_parameter(key, value, &block)
  assert_invalid_config_param(
    'parameters',
    { key => value },
    %Q.^(DAEMON_OPTS="|\\s*)-p #{Shellwords.escape(key)}=#{Shellwords.escape(value)}\\b.,
    &block
  )
end

def assert_exception_for_parameter(key, value, error, &block)
  assert_exception_for_config_param('parameters', { key => value }, error, &block)
end

def assert_valid_runtime_option(value, &block)
  assert_valid_config_param('runtime_options', [value], %Q.^(DAEMON_OPTS="|\\s*)#{value}\\b., &block)
end

def assert_invalid_runtime_option(value, &block)
  assert_invalid_config_param('runtime_options', [value], %Q.^(DAEMON_OPTS="|\\s*)#{value}\\b., &block)
end

def assert_exception_for_runtime_option(value, error, &block)
  assert_exception_for_config_param('runtime_options', [value], error, &block)
end

def assert_valid_storage_spec(input, output, &block)
  assert_valid_config_param('storage_spec', input, %Q.VARNISH_STORAGE=#{output}., &block)
end

def assert_invalid_storage_spec(input, output, &block)
  assert_invalid_config_param('storage_spec', input, %Q.VARNISH_STORAGE=#{output}., &block)
end

def assert_exception_for_storage_spec(input, error, &block)
  assert_exception_for_config_param('storage_spec', input, error, &block)
end

def assert_valid_config_param(setting, value, test_expression, &block)
  with_config_param(setting, value) do
    it {
      instance_eval(&block) if block_given?
      should have_a_config_file.with_content(Regexp.new(test_expression))
    }
  end
end

def assert_invalid_config_param(setting, value, test_expression, &block)
  with_config_param(setting, value) do
    it {
      instance_eval(&block) if block_given?
      should_not have_a_config_file.with_content(Regexp.new(test_expression))
    }
  end
end

def assert_exception_for_config_param(setting, value, error, &block)
  with_config_param(setting, value) do
    it {
      instance_eval(&block) if block_given?
      expect(subject).to raise_error(error)
    }
  end
end

def have_a_config_file
  contain_file('/tmp/varnish')
end

def with_config_params(settings, &block)
  context "#{settings.inspect}" do
    let(:params) {{
      'config' => {
        'vcl_content' => 'return(pass);',
        'params_path' => '/tmp/varnish'
      }.merge(settings)
    }}
    instance_eval(&block)
  end
end

def with_config_param(setting, value, &block)
  with_config_params({setting => value}, &block)
end
