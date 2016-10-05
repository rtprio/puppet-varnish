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
require 'puppet'

module Varnish
  class Error < StandardError; end
  class InvalidStorageSpec < Error; end
  class InvalidStorageSize < InvalidStorageSpec; end
  class InvalidStoragePath < InvalidStorageSpec; end
  class InvalidStorageType < InvalidStorageSpec; end
  class UnableToFindMountpoint < Error; end

  class StorageSpec
    attr_reader :scope, :type, :size, :path, :granularity
    private :scope, :type, :size, :path, :granularity

    def initialize(scope, spec)
      @scope = scope

      @type, *components = spec.split(',')
      unless %w[malloc file persistent].include? @type
        fail InvalidStorageType, "Invalid storage type: '#{@type}'"
      end

      case @type
        when 'malloc' then
          unless (size = components.shift).nil?
            @size = SizeSpec.new(size, memory_max_size)
          end
        when 'file', 'persistent' then
          unless (@path = components.shift).nil?
            begin
              scope.function_validate_absolute_path([@path])
            rescue Puppet::ParseError
              fail InvalidStoragePath, "Invalid storage path: #{path}; expected an absolute path"
            end

            unless (size = components.shift).nil?
              @size = SizeSpec.new(size, blockdevice_max_size)
              unless persistent? || (granularity = components.shift).nil?
                @granularity = SizeSpec.new(granularity, blockdevice_max_size)
              end
            end
          end
      end
    end

    def malloc?() type == 'malloc'; end
    def file?() type == 'file'; end
    def persistent?() type == 'persistent'; end

    def to_s
      [type].tap { |components|
        case type.to_sym
          when :malloc then
            components << size
          when :file, :persistent then
            components << path
            components << size
            components << granularity if file?
        end
      }.compact.collect(&:to_s).join(',')
    end

  private

    def blockdevice_max_size
      mountpoints ||= scope.to_hash.keys.grep(/^mountpoint_/).collect { |name| name.gsub(/_(path|size)$/, '') }
      Hash[mountpoints.each_with_object({}) { |key, hash|
        hash[scope.lookupvar("#{key}_path")] = scope.lookupvar("#{key}_size").to_i
      }.sort { |a,b| b.first.size <=> a.first.size }].each do |mountpoint, size|
        return size if path.start_with? mountpoint
      end

      fail UnableToFindMountpoint, "unable to find mountpoint for path: #{path}; " \
                                   "are the varnish module's mountpoint facts loading correctly?"
    end

    def memory_max_size
      scope.lookupvar('memorysize_mb').to_f * (1024 ** 2)
    end
  end

  class SizeSpec
    MODIFIER_MAP = Hash.new(1).merge({
      'k' => 1024 ** 1,
      'm' => 1024 ** 2,
      'g' => 1024 ** 3,
      't' => 1024 ** 4,
      'p' => 1024 ** 5,
    })

    attr_reader :size, :modifier, :capacity
    private :size, :modifier, :capacity

    def initialize(spec, capacity)
      @capacity = capacity

      if result = spec.match(/^(?<size>\d+(?:\.\d+)?)(?<modifier>[bkmgt%])?/i)
        @size, @modifier = result.captures[0..1]
        @size = Float(@size) rescue @size.to_i
        @size > @size.to_i ? @size : @size.to_i
      else
        fail InvalidStorageSize, "Not a valid size string: #{spec}"
      end

      if percent? && @size > 100
        fail InvalidStorageSize, "size can't exceed capacity (#{size == size.to_i ? size.to_i : size}% > 100%)"
      elsif as_bytes > capacity
        fail InvalidStorageSize, "size can't exceed capacity (#{as_bytes.to_i} > #{capacity})"
      end
    end

    def to_s
      value, round_next = as_bytes, false
      MODIFIER_MAP.to_a.reverse.each { |modifier, modsize|
        modified = round_next ? (value / modsize.to_f).round : value / modsize.to_f
        if modified >= 1
          # if we have a non-fractional number, then we're good to go
          return "#{modified.to_i}#{modifier}" if modified.to_i == modified
          # otherwise, step down to the next modifier and round it off
          round_next = true
        end
      }
      value.to_i.to_s
    end
    alias_method :normalized, :to_s

  private

    def percent?
      modifier == '%'
    end

    def percent_of_capacity
      capacity * (size / 100.0)
    end

    def as_bytes
      percent? ? percent_of_capacity : (size * MODIFIER_MAP[modifier])
    end
  end
end
