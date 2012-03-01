require 'fileutils'

require 'onboard/extensions/process'

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

        class << self
          # true if *any* save/restore process is running
          def running?
            Dir.glob "#{VARRUN}/qemu-*.snapshot.pid" do |pidfile|
              pid = File.read(pidfile).to_i
              return true if pid > 0 and ::Process.running? pid 
            end
            # Maybe we missed something...?
            `pidof qemu-img`.split.each do |pidstr|
              pid = pidstr.to_i
              p = OnBoard::System::Process.new pid
              return true if (
                File.basename(p.exe) == 'qemu-img' and
                p.cmdline[1] == 'snapshot'
              )
            end
            return false
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

