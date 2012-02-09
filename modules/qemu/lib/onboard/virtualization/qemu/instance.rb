require 'json'
require 'socket'

gem 'rmagick'
autoload :Magick, 'RMagick'

require 'onboard/extensions/process'
require 'onboard/system/command'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        SAVEVM_TIMEOUT = 240
        # Very slow with qcow2 and cache=writethrough;
        # as opposite, it take a few seconds with cache=unsafe :-P

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
            -loadvm
            -vnc
            -k
            -pidfile
          }.each do |o|
            cmdline << %Q{#{o} "#{opts[o]}" }     if 
                opts[o] and opts[o].to_s =~ /\S/  
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
              # Non empty nor space-only Strings
              %w{if file media cache}.each do |par|  
                drive_args << %Q{#{par}="#{d[par]}"} if d[par] =~ /\S/
              end
              # Numeric or nil
              %w{index bus unit}.each do |par|
                drive_args << %Q{#{par}=#{d[par]}} if d[par] # numeric or nil
              end
              cmdline << '-drive' << ' ' << drive_args.join(',') << ' '
            end
          end

          # Useful defaults: TODO? make them configurable?
          cmdline << '-boot' << ' ' << 'menu=on,order=dc' << ' '
              # boot order: CDROM, disk (Network would be 'n') 

          # cmdline << '-usbdevice' << ' ' << 'tablet' << ' '  
          # The above should fix some problems with VNC,
          # but you have problems anyway with -loadvm ...
          #
          # Solution: use a VNC client like Vinagre, supporting
          # capture/release.
          
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

        def loadvm_on_next_boot(name)
          @config['-loadvm'] = name
          @config.save
        end

        def powerdown
          @monitor.sendrecv 'system_powerdown'
          loadvm_on_next_boot false
        end

        def quit
          @monitor.sendrecv 'quit'
        end

        def savevm(name, *opts)
          @monitor.sendrecv "savevm #{name}", :timeout => SAVEVM_TIMEOUT
          if opts.include? :loadvm_on_next_boot
            loadvm_on_next_boot name
          end
        end

        def savevm_quit
          pause
          savevm DEFAULT_SNAPSHOT, :loadvm_on_next_boot
          quit
        end

        def delete
          quit if running?
          FileUtils.rm_f @config.file
        end

        def screendump(format='ppm')
          ppmfile = "#{VARRUN}/qemu-#{uuid_short}.ppm"
          @monitor.sendrecv "screendump #{ppmfile}"
          case format
          when 'png'
            pngfile = "#{VARRUN}/qemu-#{uuid_short}.png"
            begin
              ppm = Magick::ImageList.new ppmfile
              ppm.write pngfile
              FileUtils.rm_f ppmfile 
                  # May be large, on a RAM fs, let's save memory.
              return pngfile
            rescue Magick::ImageMagickError
              LOGGER.handled_error $!
              return nil
            end
          when 'ppm'
            return ppmfile
          else
            raise ArgumentError, "Unsupported format '#{format}'"
          end
        end

      end
    end
  end
end
