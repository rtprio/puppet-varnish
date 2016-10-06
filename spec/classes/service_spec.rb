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

describe 'varnish::service', :type => :class do
  describe 'compiles successfully' do
    it { should compile.and_raise_error(/varnish::service is private/) }
  end

  describe "with service_manage => true" do
    let(:pre_condition) { ['include ::varnish::config'] }
    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

    before(:each) {
      allow(scope).to receive(:lookupvar).with('::installed_package_systemd').and_return('228')
      allow(scope).to receive(:lookupvar).with('::varnish::config::runtime_user').and_return('varnish')
      allow(scope).to receive(:lookupvar).with('::varnish::config::default_ttl').and_return(120)
      Puppet::Parser::Functions.newfunction(:assert_private) { |args| true }
    }

    it {
      should contain_file('/etc/systemd/system/varnish.service').
             with({owner: 'root', group: 'root', mode: '0644'})
    }

    describe "varnish.service template" do
      let(:harness) { TemplateHarness.new('templates/varnish.service.erb', scope) }

      context "with non-empty settings" do
        it { result = harness.run; expect(result).to match(/^TasksMax=infinity/) }
        it { result = harness.run; expect(result).to match(/^\s+-j unix,user=varnish/) }
        it { result = harness.run; expect(result).to match(/^\s+-t 120/) }
      end

      context "with empty settings" do
        it {
          allow(scope).to receive(:lookupvar).with('::installed_package_systemd').and_return(nil)
          result = harness.run; expect(result).to match(/^#TasksMax=infinity/)
        }
        it {
          allow(scope).to receive(:lookupvar).with('::varnish::config::runtime_user').and_return(nil)
          result = harness.run; expect(result).to_not match(/^\s+-j\s+/)
        }
        it {
          allow(scope).to receive(:lookupvar).with('::varnish::config::default_ttl').and_return(nil)
          result = harness.run; expect(result).to_not match(/^\s+-t\s+/)
        }
      end
    end

    it {
      should contain_exec('systemctl_reload_varnish_service').
             with_command('/bin/systemctl daemon-reload').
             with_refreshonly(true).
             that_subscribes_to('File[/etc/systemd/system/varnish.service]').
             that_notifies('Service[varnish]').
             that_comes_before('Service[varnish]')
    }

    it {
      should contain_service('varnish').
             with_ensure('running').
             with_enable(true).
             that_subscribes_to('File[/etc/varnish/varnish.params]').
             that_subscribes_to('File[/etc/varnish/default.vcl]').
             that_requires('File[/etc/systemd/system/varnish.service]')
    }
    it {
      should contain_file('/etc/systemd/system/varnishncsa.service').
             with({owner: 'root', group: 'root', mode: '0644'}).
             with_source('puppet:///modules/varnish/varnishncsa.service')
    }

    it {
      should contain_file('/etc/sysconfig/varnishncsa').
             with({owner: 'root', group: 'root', mode: '0644'}).
             with_content(/^LOG_FORMAT="%\{Host\}i .+ grace:%\{X-Grace\}o"/)
    }

    it {
      should contain_file('/var/log/varnish').
             with({owner: 'varnishlog', group: 'varnish', mode: '1775', ensure: 'directory'})
    }

    it {
      should contain_exec('systemctl_reload_varnishncsa_service').
             with_command('/bin/systemctl daemon-reload').
             with_refreshonly(true).
             that_subscribes_to('File[/etc/systemd/system/varnishncsa.service]').
             that_notifies('Service[varnishncsa]').
             that_comes_before('Service[varnishncsa]')
    }

    it {
      should contain_service('varnishncsa').
             with_ensure('running').
             with_enable(true).
             that_subscribes_to('File[/etc/sysconfig/varnishncsa]').
             that_requires('File[/etc/systemd/system/varnishncsa.service]').
             that_requires('File[/var/log/varnish]')
    }

    context "with other parameter" do
      [true, false, 'true', 'false', 'running', 'stopped'].each do |value|
        context "service_ensure => #{value.inspect}" do
          let(:params) {{ service_ensure: value }}
          it { should contain_service('varnish').with_ensure(value) }
        end
      end

      context "service_ensure => 'bogus'" do
        let(:params) {{ service_ensure: 'bogus' }}
        it { should raise_error(Puppet::Error) }
      end

      [ true, false, 'true', 'false', 'manual', 'mask'].each do |value|
        context "service_enable => #{value.inspect}" do
          let(:params) {{ service_enable: value }}
          it { should contain_service('varnish').with_enable(value) }
        end
      end

      context "service_enable => 'bogus'" do
        let(:params) {{ service_enable: 'bogus' }}
        it { should raise_error(Puppet::Error) }
      end

    end
  end

  describe "with service_manage => false" do
    let(:pre_condition) { ['include ::varnish::config'] }
    let(:params) {{ service_manage: false }}

    before(:each) { Puppet::Parser::Functions.newfunction(:assert_private) { |args| true } }

    it { should_not contain_service('varnish') }
    it { should_not contain_service('varnishncsa') }
    it { should_not contain_file('/etc/systemd/system/varnishncsa.service') }
    it { should_not contain_file('/etc/sysconfig/varnishncsa') }
  end
end
