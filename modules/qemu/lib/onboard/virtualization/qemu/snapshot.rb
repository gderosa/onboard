require 'fileutils'

require 'onboard/extensions/process'

require 'onboard/system/process'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot

        autoload :Schedule, 'onboard/virtualization/qemu/snapshot/schedule'

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
          def running?(opts={})
            Dir.glob "#{VARRUN}/qemu-*.snapshot.pid" do |pidfile|
              pid = File.read(pidfile).to_i
              waiting_file = pidfile.sub(/\.pid$/, '.waiting') 
              waiting = File.exists? waiting_file
              next if waiting and opts[:except_waiting] 
              next if opts[:except_pid] and opts[:except_pid] == pid
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

        def name
          tag
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

