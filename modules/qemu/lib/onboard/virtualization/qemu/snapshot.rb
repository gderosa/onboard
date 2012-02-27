require 'fileutils'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot

        class VMClock # allow further data manipulation...
          def self.parse(str)
            new(str) 
          end
          def initialize(str)
            @str = str
          end
          def to_json(*a)
            @str.to_json(*a)
          end
        end

        def initialize(h)
          @data = h
        end
      
        def to_json(*a)
          @data.to_json(*a) 
        end

      end
    end
  end
end

