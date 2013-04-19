require 'fileutils'
require 'time'

class OnBoard
  module Virtualization
    module QEMU
      class Img

        ROOTDIR = File.join ENV['HOME'], 'files/QEMU'

        class << self

          def absolute_path(*a)
            QEMU::Config.absolute_path *a
          end

          def relative_path(*a)
            QEMU::Config.relative_path *a
          end

          # for example an image is created at: ~/files/QEMU/Win7/{idx}.qcow2
          # or ~/files/QEMU/Debian/#{idx}.raw
          def create(h)
            raise OnBoard::BadRequest, 'Virtual machine must have a name' unless
                h['vmname'] and h['vmname'] =~ /\S/
            name = h['vmname']
            if h['qemu-img'] and h['qemu-img']['create']
              size_str = h['qemu-img']['size']['G'] + 'G'
              fmt = h['qemu-img']['fmt']
              subdir = if h['qemu-img']['subdir'] =~ /^(.*)\/qemu\/?$/i
                         h['qemu-img']['subdir']
                       else
                         h['qemu-img']['subdir'] + '/QEMU'
                       end
              dir = File.join QEMU::FILESDIR, subdir, name
              System::Command.run "mkdir -p '#{dir}'", :sudo # sudo, otherwise 
                  # we should ensure that the onboard user has the same UID 
                  # across the cluster, in case directories are on a 
                  # distributed file system.
              filepath = "#{dir}/disk#{h['idx']}.#{fmt}"
              if File.exists? filepath
                FileUtils.mv filepath, "#{filepath}.old"
              end
              System::Command.run(
                  "qemu-img create -f #{fmt} '#{filepath}' #{size_str}", :sudo, :raise_BadRequest) 
              return filepath
            end
          end

        end

        def initialize(h)
          @drive_config = h[:drive_config]
          @file = @drive_config['file']
        end

        def snapshots
          list = []
          if @file # and File.exists? @file
            cmd = %Q{qemu-img snapshot -l "#{@file}"} 
            out = `sudo #{cmd}` # sudo to access gluster://
            out.each_line do |line|
              if line =~ /^(\d+)\s+(\S|\S.*\S)\s+(\d*\.?\d*[TGMk]?)\s+(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)\s+(\d+:\d\d:\d\d\.\d+)\s*$/ 
                list << Snapshot.new(
                  :id       =>                                $1.to_i,
                  :tag      =>                                $2,
                  :vmsize   =>                                $3,
                  :time     => Time.parse(                    $4),
                  :vmclock  => QEMU::Snapshot::VMClock.parse( $5)
                )
              end
            end
          end
          return list
        end

        def info
          h = {}
          if @file # and File.exists? @file
            `sudo qemu-img info "#{@file}"`.each_line do |line|
              break if line =~ /^\s*Snapshot list:/
              if line =~ /([^:]+):([^:]+)/ 
                k = $1
                v = $2
                h[k.strip.gsub(' ', '_')] = v.strip if h and v
              end
            end
            return h
          end
        end

      end
    end
  end
end

