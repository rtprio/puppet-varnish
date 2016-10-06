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
source 'https://rubygems.org'

group :test do
  gem 'rake',                   '= 10.4.2'
  gem 'deep_merge',             '= 1.0.1'
  gem 'puppet-lint',            '= 1.1.0'
  gem 'rspec-mocks',            '= 2.99.3'
  gem 'rspec-puppet',           '= 2.2.0'
  gem 'rspec-puppet-utils',     '= 2.2.1'
  gem 'puppetlabs_spec_helper', '= 0.8.2'
  gem 'metadata-json-lint',     '= 0.0.11'
  gem 'puppet-syntax',          '= 2.0.0'
  gem 'puppet', ENV['PUPPET_VERSION'] || '~> 3.7.0'
end

group :development do
  gem 'travis',      '= 1.7.5'
  gem 'travis-lint', '= 2.0.0'
  gem 'puppet-blacksmith', :require => false
  gem 'rabbitt-githooks', '~> 1.6.0', :require => false
end
