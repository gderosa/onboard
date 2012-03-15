require 'yaml'
require 'uuid'
require 'fileutils'

require 'onboard/extensions/process'

class OnBoard
  module Virtualization
    module QEMU

      ROOTDIR ||= File.realpath File.join File.dirname(__FILE__), '..'
      # TODO: do not hardcode so badly 
      FILESDIR = '/home/onboard/files'
      BINDIR = ROOTDIR + '/bin'

      DEFAULT_SNAPSHOT = '_last'

      autoload :Config,   'onboard/virtualization/qemu/config'
      autoload :Instance, 'onboard/virtualization/qemu/instance'
      autoload :Img,      'onboard/virtualization/qemu/img'
      autoload :Monitor,  'onboard/virtualization/qemu/monitor'
      autoload :Network,  'onboard/virtualization/qemu/network'
      autoload :Snapshot, 'onboard/virtualization/qemu/snapshot' 
      autoload :VNC,      'onboard/virtualization/qemu/vnc'

      class << self

        def get_all
          ary = []
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            begin
              config = Config.new(:config => YAML.load(File.read file)) 
              ary << Instance.new(config)
            rescue TypeError
              LOGGER.error "qemu: Found an invalid config file: #{file}"
            end
          end
          return ary
        end

        def find(h)
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            config = Config.new(:config => YAML.load(File.read file))
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
                vm.send cmd
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

        def save
          File.open "#{CONFDIR}/common/instances.yml", 'w' do |f|
            f.write YAML.dump get_all
          end
        end

        def restore
          # TODO: DRY this config file name
          return unless File.exists? "#{CONFDIR}/common/instances.yml"
          saved_VMs   = YAML.load File.read "#{CONFDIR}/common/instances.yml"
          current_VMs = get_all
          saved_VMs.each do |saved_vm|
            # QEMU::Instance#running is the saved state
            # QEMU::Instance#running? is the actual state
            current_VM = current_VMs.find{|vm| vm.uuid == saved_vm.uuid} 
            current_VM.start if saved_vm.running and not current_VM.running?
          end
        end

      end

    end
  end
end
