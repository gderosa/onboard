require 'json'
require 'socket'

require 'onboard/extensions/process'
require 'onboard/system/command'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        attr_reader :config

        def initialize(config)
          @config   = config
          update_info
          @monitor = Monitor.new config['-monitor']
        end

        def update_info
          @running  = running?
          @pid      = pid
        end

        def uuid;       @config.uuid;       end
        def uuid_short; @config.uuid_short; end

        def to_h
          {
            'config'  => @config.to_h,
            'running' => running?,
            'status'  => status,
          }
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

        def format_cmdline
          opts = @config.cmd['opts'] 
          exe = Config::Common.get['exe'] 
          cmdline = ''
          cmdline << %Q{#{exe} } 
          %w{
            -uuid 
            -name 
            -m
            -vnc
            -k
            -pidfile
          }.each do |o|
            cmdline << o << ' ' << opts[o] << ' ' if opts[o] =~ /\S/  
          end
          cmdline << '-daemonize' << ' ' if opts['-daemonize'] 
          if opts['-monitor']
            if opts['-monitor']['unix']
              unix_args = []
              unix_args << %Q{unix:"#{opts['-monitor']['unix']}"} 
              unix_args << 'server' if opts['-monitor']['server']
              unix_args << 'nowait' if opts['-monitor']['nowait']
              cmdline << '-monitor ' << unix_args.join(',') << ' '
            end 
          end
          if opts['-drive'].respond_to? :each
            opts['-drive'].each do |d|
              drive_args = []
              drive_args << %Q{file="#{d['file']}"} 
              drive_args << %Q{media=#{d['media']}} 
              drive_args << %Q{index=#{d['index']}} if 
                  d['index'] =~ /\S/
              drive_args << %Q{cache=#{d['cache']}} if
                  d['cache'] =~ /\S/
              cmdline << '-drive' << ' ' << drive_args.join(',') << ' '
            end
          end
          # Useful defaults: TODO? make them configurable?
          cmdline << '-boot' << ' ' << 'menu=on' << ' '
          cmdline << '-usbdevice' << ' ' << 'tablet' << ' '  # vnc etc.
          return cmdline
        end

        def start
          cmdline = format_cmdline
          return System::Command.run cmdline, :raise_Conflict
        end

        def start_paused
          cmdline = format_cmdline
          cmdline << ' ' << '-S'
          return System::Command.run cmdline, :raise_Conflict
        end

        def pid
          pidfile = @config['-pidfile']
          if pidfile and File.exists? pidfile
            return File.read(pidfile).to_i
          end
        end

        def running? 
          return Process.running?(pid) if pid
        end

        def paused?
          status =~ /paused/
        end

        def status
          return 'Not Running' unless running?
          @cache ||= {} 
          unless @cache['status'] =~ /\S/
            get_status
          end
          return @cache['status']
        end

        def get_status
          @cache['status'] = @monitor.sendrecv 'info status'
        end

        def pause
          @monitor.sendrecv 'stop'
        end

        def resume
          @monitor.sendrecv 'cont'
        end

        def powerdown
          @monitor.sendrecv 'system_powerdown'
        end

        def quit
          @monitor.sendrecv 'quit'
        end

      end
    end
  end
end
