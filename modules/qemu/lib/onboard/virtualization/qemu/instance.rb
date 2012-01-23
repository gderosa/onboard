require 'json'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        def initialize(config)
          @config = config
        end

        def to_h
          {'config' => @config.to_h}
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

      end
    end
  end
end
