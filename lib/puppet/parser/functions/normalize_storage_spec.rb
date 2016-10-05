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
require 'varnish_helper'

module Puppet::Parser::Functions
  newfunction(:normalize_storage_spec, type: :rvalue, doc: <<-'ENDHEREDOC') do |args|
      Normalizes the storage specification, adjusting sizes to match the size
      format requirements of varnish.

      Examples:
        # Assumed facts:
        #  memorysize_mb: 10240.0
        #  mountpoint_a_path: /var/lib/varnish
        #  mountpoint_a_size: 8589934592 # 8 GB

        normalize_storage_spec('malloc,10%')
        # => malloc,1g

        normalize_storage_spec('file,/var/lib/varnish,10%')
        # => malloc,
    ENDHEREDOC

    if args.length != 1
      fail Puppet::ParseError.new("normalize_storage_spec(): expected 1 argument but found #{args.length}.")
    end

    begin
      return Varnish::StorageSpec.new(self, args.first).to_s
    rescue Varnish::Error => e
      fail Puppet::ParseError, "validate_storage_spec(): #{e.message}"
    end
  end
end
