require 'onboard/extensions/hash'

class OnBoard
  # The include you missed
  module Configurable

    # http://www.railstips.org/blog/archives/2009/05/15/include-vs-extend-in-ruby/

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def get
        begin
          self.new YAML.load File.read self::CONFFILE
        rescue Errno::ENOENT
          self.new({})
        end
      end

    end

    attr_reader :data

    def initialize(h)
      @data = h.recursively_stringify_keys
    end

    def save
      FileUtils.mkdir_p self.class::CONFDIR
      File.open self.class::CONFFILE, 'w' do |f|
        f.write YAML.dump @data
      end
    end

    def [](k)
      @data[k]
    end

    def []=(k, v)
      @data[k] = v
    end

    def to_json(*a)
      export = @data.dup
      export['password'] = '<removed>' if export['password']
      export.to_json(*a)
    end

    def method_missing(metid, *args, &blk)
      if metid.to_s =~ /=$/
        @data[metid.to_s.sub(/=$/, '')] = args.first
      else
        @data[metid.to_s]
      end
    end

  end
end
