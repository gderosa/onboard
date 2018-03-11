require 'yaml'
require 'uuid'
require 'fileutils'

require 'onboard/constants'
require 'onboard/extensions/process'

class OnBoard
  module Virtualization
    module QEMU

      ROOTDIR ||= File.realpath File.join File.dirname(__FILE__), '..'
      # TODO: do not hardcode so badly 
      FILESDIR = OnBoard::FILESDIR
      BINDIR = ROOTDIR + '/bin'

      DEFAULT_SNAPSHOT = '_last'

      autoload :Config,       'onboard/virtualization/qemu/config'
      autoload :Instance,     'onboard/virtualization/qemu/instance'
      autoload :Img,          'onboard/virtualization/qemu/img'
      autoload :Monitor,      'onboard/virtualization/qemu/monitor'
      autoload :Network,      'onboard/virtualization/qemu/network'
      autoload :Snapshot,     'onboard/virtualization/qemu/snapshot' 
      autoload :VNC,          'onboard/virtualization/qemu/vnc'
      autoload :SPICE,        'onboard/virtualization/qemu/spice'
      autoload :VGA,          'onboard/virtualization/qemu/vga'
      autoload :Sound,        'onboard/virtualization/qemu/sound'
      autoload :Passthrough,  'onboard/virtualization/qemu/passthrough'

      class << self

        def net_storage_subdirs
          ary = []
          # TODO: do not hardcode '[network]'
          Dir.glob("#{FILESDIR}/*network*/*/*/*").each do |abspath|
            ary << Config.relative_path(abspath) 
          end
          ary
        end

        def get_all
          ary = []
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            begin
              config = Config.new(:config => YAML.load(File.read file)) 
              ary << Instance.new(config)
            rescue TypeError, NoMethodError
              LOGGER.error "qemu: Found an invalid config file: #{file}"
            end
          end
          return ary
        end

        def find(h)
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            begin
              config = Config.new(:config => YAML.load(File.read file))
            rescue NoMethodError
              next
            end
            if config.uuid =~ /^#{h[:vmid]}/ # may be uuid or a shortened uuid
              return Instance.new(config)
            end
          end
          return nil
        end

        def manage(h)
          all = get_all

          if h[:http_params]
            params = h[:http_params]
            %w{
start start_paused pause resume powerdown delete
            }.each do |cmd|
              if params[cmd] and params[cmd]['uuid']
                uuid = params[cmd]['uuid']
                vm = all.find{|x| x.uuid == uuid}  
                vm.loadvm_on_next_boot false unless 
                    params['saverestore'] and params['saverestore'][uuid] == 'on'
                if cmd == 'start' and params['run_as_root'] == 'on' 
                  vm.send :start, :run_as_root
                else
                  vm.send cmd
                end
              end
            end
            if params['quit'] and params['quit']['uuid']
              uuid = params['quit']['uuid']
              vm = all.find{|x| x.uuid == uuid}
              if params['saverestore'] and params['saverestore'][uuid] == 'on'
                vm.savevm_quit
              else
                vm.loadvm_on_next_boot false
                vm.quit
              end
            end

            # eject / change removable media: cdrom etc.
            params['drive'].each_pair do |vm_uuid, drives|
              vm = all.find{|x| x.uuid == vm_uuid} 
              drives.each_pair do |drive_name, drive|
                if    drive['action'] == 'eject'
                  vm.drive_eject  drive_name
                  vm.drive_save   drive_name, nil
                elsif drive['action'] == 'change'         and 
                    not drive['file'] =~ /^\s*\[.*\]\s*$/
                        # special messages like '[choose an image]' 
                  drive_file = QEMU::Img.absolute_path drive['file']
                  vm.drive_change drive_name, drive_file
                  vm.drive_save   drive_name, drive_file
                end
              end
            end if params['drive'].respond_to? :each_pair 

            # Snapshots # TODO: DRY DRY DRY
            if params['snapshot_take'] 
              raise OnBoard::BadRequest, 'Snapshot must have a name!' unless
                  params['snapshot_take']['name'] =~ /\S/
              raise OnBoard::BadRequest, 'Another snapshot process is running!' if
                  QEMU::Snapshot.running?
              cmd = %Q{#{BINDIR}/snapshot take #{params['vmid']} "#{params['snapshot_take']['name']}"}          
              cmd << %Q{ "#{params['snapshot_drive']}"} if 
                  params['snapshot_drive'] =~ /\S/
              System::Command.run cmd 
            end
            if params['snapshot_apply'] 
              raise OnBoard::BadRequest, 'Snapshot must have a name!' unless
                  params['snapshot_apply']['name'] =~ /\S/
              raise OnBoard::BadRequest, 'Another snapshot process is running!' if
                  QEMU::Snapshot.running?
              cmd = %Q{#{BINDIR}/snapshot apply #{params['vmid']} "#{params['snapshot_apply']['name']}"}          
              cmd << %Q{ "#{params['snapshot_drive']}"} if 
                  params['snapshot_drive'] =~ /\S/
              System::Command.run cmd 
            end
            if params['snapshot_delete'] 
              raise OnBoard::BadRequest, 'Snapshot must have a name!' unless
                  params['snapshot_delete']['name'] =~ /\S/
              raise OnBoard::BadRequest, 'Another snapshot process is running!' if
                  QEMU::Snapshot.running?
              cmd = %Q{#{BINDIR}/snapshot delete #{params['vmid']} "#{params['snapshot_delete']['name']}"}          
              cmd << %Q{ "#{params['snapshot_drive']}"} if 
                  params['snapshot_drive'] =~ /\S/
              System::Command.run cmd 
            end

            if params['snapshot_schedule']
              QEMU::Snapshot::Schedule.manage :http_params => params
            end
          end
        end

        def cleanup
          Dir.glob "#{VARRUN}/qemu-*.pid" do |pidfile|
            if pidfile =~ /qemu-([^\.]+)\.pid/ 
              vmid = $1
              unless Process.running? File.read(pidfile).to_i
                Dir.glob "#{VARRUN}/qemu-#{vmid}.*" do |file|
                  FileUtils.rm_f file 
                end
              end
            end
          end
        end

        def reset_capabilities 
          Network::NIC.   models :reset
          Sound::Hardware.models :reset
        end

        def save
          FileUtils.mkdir_p "#{CONFDIR}/common"
          File.open "#{CONFDIR}/common/instances.yml", 'w' do |f|
            f.write YAML.dump get_all
          end
        end

        def restore
          # TODO: DRY this config file name
          return unless File.exists? "#{CONFDIR}/common/instances.yml"
          saved_VMs     = YAML.load File.read "#{CONFDIR}/common/instances.yml"
          current_VMs   = get_all
          failed_VMs    = []
          restored_VMs  = []
          saved_VMs.each do |saved_vm|
            # QEMU::Instance#running is the saved state
            # QEMU::Instance#running? is the actual state
            current_VM = current_VMs.find{|vm| vm.uuid == saved_vm.uuid} 
            if current_VM
              if saved_vm.running and not current_VM.running?
                begin
                  print "\n  Starting VM '#{current_VM.name}'#{' (with machine state)' if current_VM.opts['-loadvm'] =~ /\S/}... "
                  STDOUT.flush
                  current_VM.start
                  print 'OK'
                  STDOUT.flush
                  if current_VM.opts['-loadvm'] == DEFAULT_SNAPSHOT
                    current_VM.loadvm_on_next_boot false
                    LOGGER.error "DEBUG: #{__FILE__}##{__LINE__}: current_VM.loadvm_on_next_boot false"
                    # After a possible host power failure,
                    # do not force loading from DEFAULT_SNAPSHOT,
                    # which may not be recent at all.                    #
                    # 
                    # It should be up
                    # to the administrator to decide if load a snapshot 
                    # or try to recover
                    # even from an inconsistent guest filesystem (whose state
                    # would be completely lost with -loadvm).
                  end
                  restored_VMs << current_VM
                rescue OnBoard::Error
                  print 'ERR!'
                  STDOUT.flush
                  failed_VMs << current_VM
                  errmsg = "Couldn't start VM ``#{current_VM.name}''"
                  LOGGER.error errmsg
                end
              end
            end
          end
          puts if restored_VMs.any? or failed_VMs.any?
          if failed_VMs.any?
            raise \
                OnBoard::RestoreFailure, "Some VMs were not restored correctly #{failed_VMs.map{|vm| vm.name}} (see logs)" 
          end
        end

      end

    end
  end
end
