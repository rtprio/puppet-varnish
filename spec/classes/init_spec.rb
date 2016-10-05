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
require 'spec_helper'

describe 'varnish', :type => :class do
  let(:params) {{
    'config' => {
      'secret_pass'     => 'foo',
      'vcl_content'     => 'return(pass);',
      'vcl_config_file' => '/etc/varnish/default.vcl',
      'parameters'      => {
        'a' => 'b',
        'c' => 'd'
      },
      'runtime_options' => [
        '-a 1,2,3',
        '-b 0',
        '-c',
        '-d e'
      ]
    }
  }}

  describe 'compiles successfully' do
    it { should compile.with_all_deps }
  end

  describe 'contains expected classes and relationships' do
    it { should contain_class('varnish') }
    it { should contain_anchor('varnish::begin').that_comes_before('Class[varnish::package]') }
    it { should contain_class('varnish::package').that_requires('Anchor[varnish::begin]') }
    it { should contain_class('varnish::package').that_comes_before('Class[varnish::config]') }
    it { should contain_class('varnish::config').that_requires('Class[varnish::package]') }
    it { should contain_class('varnish::config').that_notifies('Class[varnish::service]') }
    it { should contain_class('varnish::config').that_comes_before('Class[varnish::service]') }
    it { should contain_class('varnish::service').that_requires('Class[varnish::config]') }
    it { should contain_class('varnish::service').that_comes_before('Anchor[varnish::end]') }
    it { should contain_anchor('varnish::end').that_requires('Class[varnish::service]') }
    it { should contain_file('/etc/varnish/varnish.params') }
    it { should contain_package('varnish').with_ensure('installed') }
    it { should contain_service('varnish').with({ 'ensure' => 'running', 'enable' => 'true', }) }
    it { should contain_service('varnish').that_subscribes_to([ 'File[/etc/varnish/varnish.params]', 'File[/etc/varnish/default.vcl]']) }
  end

  describe 'contains expected files' do
    it {
      should contain_file('/etc/varnish/varnish.params').
             with({ 'owner' => 'root', 'group' => 'root', 'mode' => '0644' })
      should contain_file('/etc/varnish/default.vcl').
             with({'owner' => 'root', 'group' => 'root', 'mode' => '0644' })
      should contain_file('/etc/varnish/secret').
             with({ 'owner' => 'root', 'group' => 'root', 'mode' => '0600' })
    }
  end

  describe "parameters" do
    let(:facts) do
      {
        memorysize_mb:     100.0 * 1024,
        mountpoint_a_path: '/var/tmp/data', mountpoint_a_size: 100.0 * (1024 ** 3),
        mountpoint_b_path: '/var/tmp',      mountpoint_b_size: 10.0 *  (1024 ** 3),
        mountpoint_c_path: '/',             mountpoint_c_size: 1.0 *   (1024 ** 3),
        mountpoint_d_path: '/var/tmp/jazz', mountpoint_d_size: 100.0 * (1024 ** 2),
      }
    end

    with_config_param('params_path', '/tmp/varnish.params') do
      it { should contain_file('/tmp/varnish.params') }
    end

    assert_storage_spec('malloc,10%', 'malloc,10g')
    assert_storage_spec('file,/var/tmp,10%', 'file,/var/tmp,1g')
    assert_storage_spec('persistent,/,10%', 'persistent,/,104858k')
    assert_storage_spec('file,/var/tmp/data,10.532%,4096', 'file,/var/tmp/data,10785m,4k')
    assert_storage_spec('file,/var/tmp/data,2048m', 'file,/var/tmp/data,2g')
  end
end
