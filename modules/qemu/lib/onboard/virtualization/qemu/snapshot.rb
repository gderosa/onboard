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

        def disk_only?
          vmsize == '0'
        end

        def full_vm?
          not disk_only?
        end

        def method_missing(id, *a)
          if @data.keys.include? id or @data.keys.include? id.to_s
            @data[id] or @data[id.to_s] 
          else
            raise NoMethodError, "Undefined method `#{id}' for #{self}"
          end
        end
      
        def to_json(*a)
          @data.to_json(*a) 
        end

      end
    end
  end
end

