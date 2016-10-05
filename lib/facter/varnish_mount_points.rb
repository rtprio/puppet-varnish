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
  module MountPoints
    extend self
    def get
      mount_points  = Facter::Util::Resolution.exec('/bin/mount -l -t xfs,ext2,ext3,ext4,btrfs,reiser4,zfs')
      @mount_points = mount_points.lines.each_with_object({}) { |line,hash|
        next unless results = line.match(/^(?<device>\S+)\s+on\s+(?<mountpoint>\S+)/)
        device, mountpoint = results.captures
        hash[device] = OpenStruct.new(
          basename: "mountpoint" << device.tr('/-', '_'),
          mountpoint: mountpoint,
          size: Facter::Util::Resolution.exec("blockdev --getsize64 #{Shellwords.escape(device)}")
        )
      }.freeze
    rescue
      {}
    end
  end unless defined? MountPoints
end unless defined? Varnish

Varnish::MountPoints.get.each do |device, data|
  Facter.add("#{data.basename}_path") { setcode { data.mountpoint } }
  Facter.add("#{data.basename}_size") { setcode { data.size } }
end
