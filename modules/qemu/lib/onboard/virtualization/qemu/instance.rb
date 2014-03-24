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
          @config = config
          @cache = {}
          @monitor = Monitor.new config['-monitor']
          @qmp = Monitor::QMP.new config['-qmp'] if config['-qmp']
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
              'schedule'      => snapshot_cron_entry  ? 
                  snapshot_cron_entry.to_hash         :
                  {},
            }
          }
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

        def opts
          @config.cmd['opts']
        end

        def format_cmdline          

          return @config.force_command_line if @config.force_command_line

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
            -vga
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
          cmdline << '-daemonize' << ' ' if opts['-daemonize'] 
          %w{-monitor -qmp}.each do |k| # TODO: switch to QMP completely
            if opts[k]
              if opts[k]['unix']
                unix_args = []
                unix_args << %Q{unix:"#{opts[k]['unix']}"}
                unix_args << 'server' if opts[k]['server']
                unix_args << 'nowait' if opts[k]['nowait']
                cmdline << k << ' ' << unix_args.join(',') << ' '
              end
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

          if opts['-rtc'].respond_to? :each_pair
            args = []
            opts['-rtc'].each_pair do |k,v|
              args << "#{k}=#{v}"
            end
            cmdline << '-rtc ' << args.join(',') << ' '
          end

          # This SHOLUD NOT be used; use -device instead
          if opts['-usbdevice'].respond_to? :each
            opts['-usbdevice'].each do |device|
              if    device['type'] == 'disk'
                cmdline << "-usbdevice disk:#{device['file']}" << ' '
              elsif device['type'] == 'host'
                if    device['bus']       and device['addr']
                  cmdline << "-usbdevice host:#{device['bus']}.#{device['addr']}"             << ' '
                elsif device['vendor_id'] and device['product_id']
                  cmdline << "-usbdevice host:#{device['vendor_id']}:#{device['product_id']}" << ' '
                end
              end
            end
          end
          # END This SHOULD NOT be used: use -device instead

          # Add various kinds of devices, including USB and PCI passthrough
          if opts['-device'].respond_to? :each
            opts['-device'].each do |device|
              driver = device['driver'] || device['type']
              next unless driver
              cmdline << "-device " << driver
              device.each_pair do |k, v|
                cmdline << ",#{k}=#{v}" unless 
                    %{driver type}.include? k or k =~ /^_/ # e.g. '_comment'
              end
              cmdline << ' '
            end
          end

          if opts['-drive'].respond_to? :each
            opts['-drive'].each do |d|
              drive_args = []
              # Non empty nor space-only Strings
              %w{serial if media cache}.each do |par|  
                drive_args << %Q{#{par}="#{d[par]}"} if d[par] =~ /\S/
              end
              # Disk image might be on distributed storage...
              if d['file_url'] # e.g. gluster:// -- but qemu-img still use mount point
                drive_args << %Q{file="#{d['file_url']}"}
              elsif d['file']
                drive_args << %Q{file="#{d['file']}"}
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

          # (Host) serial ports
          if opts['-serial'].respond_to? :each
            opts['-serial'].each do |device|
              cmdline << '-serial' << ' ' << device << ' '
            end
          end

          # Useful defaults: TODO? make them configurable?
          #
          # Boot order: CDROM, disk (Network would be 'n')
          cmdline << '-boot' << ' ' << 'menu=on,order=dc' << ' '
          # 
          # Guest CPU will have host CPU features ('flags') 
          cmdline << '-cpu' << ' ' << 'host' << ' '
=begin
          cmdline << '-usbdevice' << ' ' << 'tablet' << ' '  
          # The above should fix some problems with VNC,
          # but you have problems anyway with -loadvm ...
          #
          # Solution: use a VNC client like Vinagre, supporting
          # capture/release.
=end
          cmdline << '-enable-kvm' << ' ' 

          cmdline << opts['append'] if opts['append'] 

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

        def prepare_pci_passthrough
          if opts['-device']
            opts['-device'].each do |device|
              if Passthrough::PCI::TYPES.include? (device['driver'] || device['type']) # compat, 'driver' preferred
                Passthrough::PCI.prepare device
              end
            end
          end
        end

        def start(*opts)
          # WARNING: opts is also a sugar method of this class...

          QEMU.cleanup

          # Circumvent a possible QEMU bug (as of 1.6.1) when a USB device
          # is passed-through. (assertion failed)
          unless opts.include? :paused
            if @config.cmd['opts']['-loadvm']
              msg = start :paused, *opts
              drives # a way to wait for QMP/Monitor sockets ready
              msg[:resume_monitor_out] = resume
              return msg
            end
          end

          # Auto-update from previous versions' configs 
          # which didn't use QMP.
          @config.upgrade :add_qmp and @config.save
          
          cmdline = format_cmdline
          cmdline << ' -S' if opts.include? :paused
          cmdline << " -runas #{ENV['USER']}" if config.drop_privileges?
          begin
            prepare_pci_passthrough
            msg = System::Command.run "sh -c 'ulimit -l unlimited ; #{cmdline}'", :sudo, :raise_Conflict
              # ``ulimit -l unlimited'' to circumvent problems with VFIO and 
              # limits on locking memory. The QEMU process must be child 
              # of the process wich sets ulimit, so ulimit must me called 
              # in the same shell which launches qemu. For that reason it 
              # couldn't be moved to Instance#prepare_pci_passthrough .
            setup_networking # bridge just-created TAP(s) 
          ensure
            fix_permissions
          end
          # setup_networking
          return msg
        end

        def start_paused
          start :paused
        end

        def pid
          pidfile = @config['-pidfile']
          if pidfile and File.exists? pidfile
            begin
              return File.read(pidfile).to_i
            rescue Errno::EACCES
              fix_permissions
              retry
            end
          end
        end

        def running? 
          return Process.running?(pid) if pid
          return false
        end

        def paused?
          status =~ /paused/i
        end

        def status(opts={})
          return "Not Running#{', Snapshotting' if snapshotting?}" unless running?
          unless @cache['status'] =~ /\S/
            get_status(opts)
          end
          return @cache['status']
        end

        def get_status(opts={})
          begin
            str = @monitor.sendrecv 'info status', opts
            if str =~ /error/i
              if snapshotting?
                str = 'Running, Snapshotting' 
              end
            end
            @cache['status'] = str.sub(/^VM status(: )?/, '').strip.capitalize
          rescue Errno::EACCES
            fix_permissions
            retry
          end
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

            if @qmp.respond_to? :execute # TODO: move to drives_qmp

              @cache['block_json'] ||= @qmp.execute 'query-block'
              qmp_data = JSON.load @cache['block_json']
              qmp_return = qmp_data['return']

              return {} unless qmp_return
              
              # Compatibility with the old return value of this method
              # (which has been based on "human-redable" monitor...)
              # (and have been parsing interactive output...)
              qmp_return.each do |device|
                name = device['device']
                drives_h[name] = {
                  'removable' => device['removable'],
                  'io-status' => device['io-status'],
                }
                # merge non-Hash values of device['inserted'] into drives_h[name]
                if device['inserted'].respond_to? :each_pair
                  device['inserted'].each_pair do |k, v|
                    unless v.respond_to? :each_pair
                      drives_h[name][k] = v
                    end
                  end
                end
              end
              # This should suffice to reproduce old output...
              # Lots of data are lost here and got via qemu-img etc.

            else # Non-QMP monitor... # TODO: move to drives_hmp

              @cache['block'] ||= @monitor.sendrecv 'info block'
              @cache['block'].each_line do |line|
                name, info = line.split(/:\s+/)
                drives_h[name] = {}
                if info =~ /\[not inserted\]/
                  info.sub! /\[not inserted\]/, ''
                  drives_h[name]['file'] = nil
                end
                next unless info # in case line is something like "\r\n"
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

            end # QMP (JSON) or HMP ("human")

          end # running?

          # Now, determine correspondance with configured (non runtime)
          # drives
          @config['-drive'].each do |drive_config|
            d = QEMU::Config::Drive.new drive_config
            runtime_name = d.to_runtime_name # "ide-cd0", etc., as in monitor
            drives_h[runtime_name] ||= {}
            drives_h[runtime_name]['config'] = d
            img = QEMU::Img.new :drive_config => d

            drives_h[runtime_name]['img']               =   img.info
            drives_h[runtime_name]['img']               ||= {}
            drives_h[runtime_name]['img']['snapshots']  =   img.snapshots
            #drives_h[runtime_name]['img']['virtual_size'] = img.info['virtual_size'] if img.info
            
            # Compatibility code (don't want this to go into JSON etc.)
            class << drives_h[runtime_name]
              alias __square_brackets__orig []
              def [](k)
                case k
                when 'snapshots', 'virtual_size'
                  self['img'][k]
                else
                  __square_brackets__orig k
                end
              end
              alias __square_brackets_assign__orig []=
              def []=(k,v)
                case k
                when 'snapshots', 'virtual_size'
                  self['img'][k] = v
                else
                  __square_brackets_assign__orig k, v
                end
              end
            end

          end
          drives_h
        end

        def pause
          @monitor.sendrecv 'stop'
        end

        def resume
          @monitor.sendrecv 'cont'
        end

        def loadvm_on_next_boot(name=:__not_given__)
          return @config['-loadvm'] if name == :__not_given__

          @config['-loadvm'] = name
          @config.save
        end

        def loadvm_on_next_boot?
          @config['-loadvm']
        end

        def powerdown
          @monitor.sendrecv 'system_powerdown'
          loadvm_on_next_boot false
        end
        alias acpi_powerdown powerdown

        def quit(opts={:on_monitor_error => :kill})
          begin
            @monitor.sendrecv 'quit', :raise => :monitor
          rescue MonitorError
            if opts[:on_monitor_error] == :kill
              kill
            end
          end
        end

        def kill
          # System::Command.send_command "kill -9 #{pid}", :sudo
          p = OnBoard::System::Process.new pid
          p.kill :sudo => true, :wait => true 
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
          if opts.include? :loadvm_on_next_boot
            loadvm_on_next_boot name
          end
          @monitor.sendrecv "savevm #{name}", :timeout => SAVEVM_TIMEOUT
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
          unless File.readable? ppmfile
            System::Command.send_command "chown #{Process.uid} #{ppmfile}", :sudo
          end
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
