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
require File.expand_path('../../../../varnish_helper', __FILE__)

module Puppet::Parser::Functions
  newfunction(:validate_storage_spec, :doc => <<-'ENDHEREDOC') do |args|
    Perform validation of a varnish storage specification, ensuring that it
    it is valid for any of the three possible storage types (malloc, file or persistent)

    The following strings will validate:

        validate_storage_spec('malloc,1G')
        validate_storage_spec('file,/var/tmp,20G,16k')
        validate_storage_spec('persistent,/var/tmp,20G')

    The following strings will fail to validate, causing compilation to abort:

        validate_storage_spec('foo,1G')
        validate_storage_spec('file,var/tmp,1G')
        validate_storage_spec('persistent,/var/tmp,1.2G')
    ENDHEREDOC

    if args.length != 1
      fail Puppet::ParseError.new("validate_storage_spec(): expected 1 argument but found #{args.length}.")
    end

    begin
      Varnish::StorageSpec.new(self, args.first)
    rescue Varnish::Error => e
      fail Puppet::ParseError, "validate_storage_spec(): #{e.message}"
    end
  end
end
