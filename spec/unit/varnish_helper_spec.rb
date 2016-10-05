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
require 'rspec/mocks'
require 'spec_helper'
require 'puppet/error'
require 'varnish_helper'

describe 'Varnish::StorageSpec' do
  let(:facts) {{
    memorysize_mb:     16.0 * 1024,
    mountpoint_a_path: '/var/tmp/data', mountpoint_a_size: 100.0 * (1024 ** 3),
    mountpoint_b_path: '/var/tmp',      mountpoint_b_size: 10.0 *  (1024 ** 3),
  }}
  let(:scope) { double(:scope, to_hash: Hash[facts.collect{|k,v| [k.to_s, v]}]) }

  before(:each) do
    allow(scope).to receive(:function_validate_absolute_path) do |*args|
      next true if args.flatten.all? { |path|
        Pathname.new(path).absolute?
      }
      fail Puppet::ParseError, "not a valid absolute path"
    end

    facts.each do |key, value|
      allow(scope).to receive(:lookupvar).with(key).and_return(value)
      allow(scope).to receive(:lookupvar).with(key.to_s).and_return(value)
    end
  end

  {
    'malloc'                   => 'malloc',
    'malloc,10%'               => 'malloc,1638m',
    'malloc,25.55%'            => 'malloc,4186m',
    'malloc,101%'              => Varnish::InvalidStorageSize,
    'malloc,16385m'            => Varnish::InvalidStorageSize,
    'malloc,badsize'           => Varnish::InvalidStorageSize,

    'file'                     => 'file',
    'file,/var/tmp'            => 'file,/var/tmp',
    'file,/tmp,10%'            => Varnish::UnableToFindMountpoint,
    'file,/tmp,10g'            => Varnish::UnableToFindMountpoint,
    'file,var/tmp'             => Varnish::InvalidStoragePath,
    'file,/var/tmp,badsize'    => Varnish::InvalidStorageSize,
    'file,/var/tmp,1%,badsize' => Varnish::InvalidStorageSize,
    'file,/var/tmp,101%'       => Varnish::InvalidStorageSize,
    'file,/var/tmp,10.5g,8192' => Varnish::InvalidStorageSize,
    'file,/var/tmp,5.5g,8192'  => 'file,/var/tmp,5632m,8k',

    'persistent'               => 'persistent',
    'persistent,/var/tmp'      => 'persistent,/var/tmp',
    'persistent,var/tmp'       => Varnish::InvalidStoragePath,
    'persistent,/var/tmp,101%' => Varnish::InvalidStorageSize,
  }.each do |spec, expectation|
    context "with spec => #{spec}" do
      if expectation.is_a?(Class) && Varnish::Error >= expectation
        it { expect { Varnish::StorageSpec.new(scope, spec).to_s }.to raise_error(expectation) }
      else
        it { expect(Varnish::StorageSpec.new(scope, spec).to_s).to eq(expectation) }
      end
    end
  end
end
