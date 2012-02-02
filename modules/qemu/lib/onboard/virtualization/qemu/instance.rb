require 'json'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        attr_reader :config

        def initialize(config)
          @config = config
        end

        def uuid;       @config.uuid;       end
        def uuid_short; @config.uuid_short; end

        def to_h
          {'config' => @config.to_h}
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

        def start
          puts "starting #{uuid}" 
        end

      end
    end
  end
end
