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
require 'facter'
require 'shellwords'
require 'ostruct'

module Varnish
  module PackageVersions
    extend self

    def installed
      result = %x( /bin/yum list installed systemd varnish{,-{mib,modules}} --quiet --color=no 2>&1 | grep x86_64 ).strip
      result.lines.each_with_object({}) { |line, hash|
        name, version = line.split(/\s+/)[0..1]
        hash[name.split('.').first] = OpenStruct.new(
          version: version.split('-').first,
          safename: name.split('.').first.gsub(/[\W-]/, '_')
        )
      }
    end

    def available
      result = %x( /bin/yum list available varnish{,-{mib,modules}} --quiet --color=no 2>&1 | grep x86_64 ).strip
      result.lines.each_with_object({}) { |line, hash|
        name, version = line.split(/\s+/)[0..1]
        hash[name.split('.').first] = OpenStruct.new(
          version: version.split('-').first,
          safename: name.split('.').first.gsub(/[\W-]/, '_')
        )
      }
    end
  end unless defined? PackageVersions
end

Varnish::PackageVersions.installed.each do |package, data|
  Facter.add("installed_package_#{data.safename}") { setcode { data.version } }
end

Varnish::PackageVersions.available.each do |package, data|
  Facter.add("available_package_#{data.safename}") { setcode { data.version } }
end
