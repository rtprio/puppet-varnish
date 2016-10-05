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

def have_a_config_file
  contain_file('/tmp/varnish.params')
end

def with_config_param(setting, value, &block)
  context "with #{setting} => #{value}" do
    let(:params) {{
      'config' => {
        'vcl_content' => 'return(pass);',
        'params_path' => '/tmp/varnish.params'
      }.merge({ setting => value })
    }}

    instance_eval(&block)
  end
end

def assert_storage_spec(input_spec, normalized_spec, inverted_expression:false)
  with_config_param('storage_spec', input_spec) do
    it {
      if not inverted_expression
        should have_a_config_file.
               with_content(Regexp.new("^VARNISH_STORAGE=#{normalized_spec}$"))
      else
        should_not have_a_config_file.
               with_content(Regexp.new("^VARNISH_STORAGE=#{normalized_spec}$"))
      end
    }
  end
end
