require 'pp' # DEBUG

require 'json'
require 'socket'

begin
  gem 'rmagick' # To make autoload work
rescue Gem::LoadError
  # May be available in vendor_ruby and not as a gem
end
autoload :Magick, 'RMagick'

require 'onboard/extensions/process'
require 'onboard/extensions/string'
require 'onboard/system/command'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        SAVEVM_TIMEOUT = 0 # 0 means infinite...
        # Very slow with qcow2 and cache=writethrough;
        # as opposite, it take a few seconds with cache=unsafe :-P
        #
        # Obviously snapshot operations are handled asynchronously.
        
        LOADVM_TIMEOUT = SAVEVM_TIMEOUT

        attr_reader :config, :monitor, :running

        # "running" is the saved state, "running?" is the actual state;
        # useful for save/restore after a host machine reboot

        def initialize(config)
          @config   = config
          @cache = {}
          @monitor = Monitor.new config['-monitor']
          update_info
        end

        def update_info
          @running  = running?
          @pid      = pid
        end

        def uuid;       @config.uuid;       end
        def uuid_short; @config.uuid_short; end

        def to_h
          {
            'config'        => @config.to_h,
            'running'       => running?,
            'status'        => status,
            'drives'        => drives,
            'snapshotting'  => {
              'running'       => snapshotting?,
              'waiting'       => snapshot_waiting?,
              'cmdline'       => snapshot_cmdline,
              'stdout'        => snapshot_stdout,
              'stderr'        => snapshot_stderr,
              'schedule'      => snapshot_cron_entry.to_hash
            }
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
            -soundhw
            -pidfile
          }.each do |o|
            cmdline << %Q{#{o} "#{opts[o]}" }     if 
                opts[o] and opts[o].to_s =~ /\S/  
          end
          if opts['-spice'].respond_to? :[]
            if opts['-spice']['port'] and opts['-spice']['port'].to_i != 0
              cmdline << 
"-spice port=#{opts['-spice']['port']},disable-ticketing "
              #,image-compression=[auto_glz|auto_lz|quic|glz|lz|off] 
              #,jpeg-wan-compression=[auto|never|always] 
              #,zlib-glz-wan-compression=[auto|never|always] 
              #,playback-compression=[on|off]
              #,streaming-video=[off|all|filter]
            end
          end
          cmdline << '-vga qxl '
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
          #cmdline << "-D /tmp/qemu-#{uuid_short}.log "
          #cmdline << "-debugcon file:/tmp/qemu-#{uuid_short}.dbg "
          if opts['-smp']
            args = []
            args << opts['-smp']['n'].to_s if opts['-smp']['n'].to_i > 0
            %w{cores threads sockets maxcpus}.each do |name|
              if opts['-smp'][name].to_i > 0
                value = opts['-smp'][name]
                args << "#{name}=#{value}"
              end
            end
            if args.any?
              cmdline << '-smp ' << args.join(',') << ' ' 
            end
          end
          if opts['-usbdevice'].respond_to? :each
            opts['-usbdevice'].each do |device|
              if device['type'] == 'disk'
                cmdline << "-usbdevice disk:#{device['file']}" << ' '
              end
            end
          end
          if opts['-drive'].respond_to? :each
            opts['-drive'].each do |d|
              drive_args = []
              # Non empty nor space-only Strings
              %w{serial if file media cache}.each do |par|  
                drive_args << %Q{#{par}="#{d[par]}"} if d[par] =~ /\S/
              end
              # Numeric or nil
              %w{index bus unit}.each do |par|
                drive_args << %Q{#{par}=#{d[par]}} if d[par] # numeric or nil
              end
              # Boolean
              %w{readonly}.each do |par|
                drive_args << par if d[par] 
              end
              # Boolean mapped to 'on'|'off'
              %w{snapshot}.each do |par|
                drive_args << %Q{#{par}=on} if d[par]
              end # which is different from taking/applying snapshots...
              cmdline << '-drive' << ' ' << drive_args.join(',') << ' '
            end
          end

          # Network interfaces
          opts['-net'].each do |net|
            net_args = [ net['type'] ] 
            net.each_pair do |k, v|
              net_args << "#{k}=#{v}" if v and not %w{type bridge}.include? k
            end
            if net['type'] == 'tap'
              net_args << 'script=no' 
              net_args << 'downscript=no'
            end
            cmdline << '-net' << ' ' << net_args.join(',') << ' '
          end

          # Useful defaults: TODO? make them configurable?
          #
          # Boot order: CDROM, disk (Network would be 'n')
          cmdline << '-boot' << ' ' << 'menu=on,order=dc' << ' '
          # 
          # Guest CPU will have host CPU features ('flags') 
          cmdline << '-cpu' << ' ' << 'host' << ' '

          cmdline << '-usbdevice' << ' ' << 'tablet' << ' '  
          # The above should fix some problems with VNC,
          # but you have problems anyway with -loadvm ...
          #
          # Solution: use a VNC client like Vinagre, supporting
          # capture/release.

          cmdline << '-enable-kvm' << ' ' 

          return cmdline
        end

        def setup_networking
          uid = Process.uid
          @config['-net'].select{|x| x['type'] == 'tap'}.each do |tap| 
            # TODO: use OnBoard Network library
            System::Command.run( 
                "ip link set up dev #{tap['ifname']}",
                :sudo, 
                :raise_Conflict 
            )
            System::Command.run(
                "brctl addif #{tap['bridge']} #{tap['ifname']}", 
                :sudo 
            ) if tap['bridge'] =~ /\S/ 
          end
        end

        def fix_permissions
          uid = Process.uid
          gid = Process.gid
          System::Command.run(
            "chown #{uid}:#{gid} #{VARRUN}/qemu-#{uuid_short}.*",
            :sudo
          )
        end

        def start(*opts)
          cmdline = format_cmdline
          cmdline << ' -S' if opts.include? :paused
          cmdline << " -runas #{ENV['USER']}"
          begin
            msg = System::Command.run cmdline, :sudo, :raise_Conflict
          ensure
            fix_permissions
          end
          setup_networking
          return msg
        end

        def start_paused
          start :paused
        end

        def pid
          pidfile = @config['-pidfile']
          if pidfile and File.exists? pidfile
            return File.read(pidfile).to_i
          end
        end

        def running? 
          return Process.running?(pid) if pid
          return false
        end

        def paused?
          status =~ /paused/
        end

        def status
          return "Not Running#{', Snapshotting' if snapshotting?}" unless running?
          unless @cache['status'] =~ /\S/
            get_status
          end
          return @cache['status']
        end

        def get_status
          str = @monitor.sendrecv 'info status'
          if str =~ /error/i
            if snapshotting?
              str = 'Running, Snapshotting' 
            end
          end
          @cache['status'] = str.sub(/^VM status(: )?/, '').capitalize
        end

        # TODO: move to QEMU::Snapshot::Runtime or something
        
        def snapshotting?
          pidfile = "#{VARRUN}/qemu-#{uuid_short}.snapshot.pid"
          if File.exists? pidfile
            return Process.running?(File.read(pidfile).to_i)
          else
            return nil
          end
        end
        def snapshot_waiting?
          pidfile       = "#{VARRUN}/qemu-#{uuid_short}.snapshot.pid"
          waiting_file  = "#{VARRUN}/qemu-#{uuid_short}.snapshot.waiting"
          return (
            File.exists? pidfile and
            Process.running?(File.read(pidfile).to_i) and
            File.exists? waiting_file
          )
        end
        def snapshot_cmdline
          cmdline_file = "#{VARRUN}/qemu-#{uuid_short}.snapshot.cmdline"
          if File.exists? cmdline_file
            File.read(cmdline_file).split("\0")
          end
        end
        def snapshot_stdout
          outfile = "#{VARRUN}/qemu-#{uuid_short}.snapshot.out"
          if File.exists? outfile
            File.read outfile
          end
        end
        def snapshot_stderr
          errfile = "#{VARRUN}/qemu-#{uuid_short}.snapshot.err"
          if File.exists? errfile
            File.read errfile
          end
        end
        def snapshot_cron_entry
          Snapshot::Schedule.get_entry(uuid_short) 
        end

        def drives
          drives_h = {}
          if running?
            @cache['block'] ||= @monitor.sendrecv 'info block'
            @cache['block'].each_line do |line|
              name, info = line.split(/:\s+/)
              drives_h[name] = {}
              if info =~ /\[not inserted\]/
                info.sub! /\[not inserted\]/, ''
                drives_h[name]['file'] = nil
              end
              info.split_unescaping_spaces.each do |pair|
                k, val = pair.split('=')
                if %w{removable ro encrypted locked tray-open}.include? k
                  drives_h[name][k] = case val
                                      when '0'
                                        false
                                      when '1'
                                        true
                                      else
                                        raise ArgumentError, 
  "Asking 'info block' to monitor, either #{k}=0 or #{k}=1 was expected; "
  "got #{k}=#{val} instead"
                                      end
                else
                  drives_h[name][k] = val 
                end
              end
            end
          end
          # Now, determine correspondance with configured (non runtime)
          # drives
          @config['-drive'].each do |drive_config|
            d = QEMU::Config::Drive.new drive_config
            runtime_name = d.to_runtime_name # "ide-cd0", etc., as in monitor
            drives_h[runtime_name] ||= {}
            drives_h[runtime_name]['config'] = d
            img = QEMU::Img.new :drive_config => d
            drives_h[runtime_name]['snapshots'] = img.snapshots
          end
          drives_h
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
        alias acpi_powerdown powerdown

        def quit
          @monitor.sendrecv 'quit'
        end

        def drive_eject(drive)
          @monitor.sendrecv "eject #{drive}", :log => :verbose 
        end
        alias eject drive_eject

        def drive_change(drive, file)
          @monitor.sendrecv %Q{change #{drive} "#{file}"}, :log => :verbose
        end

        def drive_save(drive, file)
          config_h = drives[drive]['config'].to_h
          idx = @config['-drive'].index( config_h )  
          if idx
            @config['-drive'][idx]['file'] = file
            @config.save
          else
            raise OnBoard::Warning, "#{__FILE__}:#{__LINE__}: No imedia/disk image has been saved for #{config_h.inspect}" 
          end
        end

        def savevm(name, *opts)
          @monitor.sendrecv "savevm #{name}", :timeout => SAVEVM_TIMEOUT
          if opts.include? :loadvm_on_next_boot
            loadvm_on_next_boot name
          end
        end

        def loadvm(name, *opts)
          @monitor.sendrecv "loadvm #{name}", :timeout => LOADVM_TIMEOUT
        end

        def delvm(name, *opts)
          @monitor.sendrecv "delvm #{name}", :timeout => LOADVM_TIMEOUT
        end

        def delvm_all(match)
          drives.each_pair do |drive_name, drive|
            drive['snapshots'].each do |snap|
              next if match[:name] and not match[:name] === snap.name
              next if match[:older_than] and snap.newer_than match[:older_than]
              delvm snap.name
            end if drive['snapshots'].respond_to? :each
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
          QEMU::Snapshot::Schedule.remove uuid_short
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

        def quick_snapshots?
          @config.quick_snapshots?
        end

        def method_missing(id, *a)
          @config.send(id, *a)
        end

      end
    end
  end
end
