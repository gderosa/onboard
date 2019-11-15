require 'fileutils'
require 'time'

require 'onboard/extensions/string'

class OnBoard
  module Virtualization
    module QEMU
      class Img

        # Please don'use url like gluster:// with qemu-img, ecen when supported;
        # it hangs for long time in case of a degraded cluster. Always prefer
        # mount points (but of course you can use urls with qemu itself, if
        # available, to get performance boost).

        ROOTDIR = File.join ENV['HOME'], 'files/QEMU'

        class << self

          def absolute_path(*a)
            QEMU::Config.absolute_path *a
          end

          def relative_path(*a)
            QEMU::Config.relative_path *a
          end

	  # gluster:// doesn't like spaces or brackets, even with quoting or
	  # escaping...
	  def sanitize_file_or_dirname(name)
            name.gsub(/\s/, '_').gsub(/[^\d\w_\+\-\.]/, '+').gsub(/\+{2,}/, '++')
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
              dir = File.join QEMU::FILESDIR, subdir, sanitize_file_or_dirname(name)
              System::Command.run "mkdir -p '#{dir}'", :sudo # sudo, otherwise
                  # we should ensure that the onboard user has the same UID
                  # across the cluster, in case directories are on a
                  # distributed file system.
              filepath = "#{dir}/disk#{h['idx']}.#{fmt}"
              if File.exists? filepath
                System::Command.run "mv '#{filepath}' '#{filepath}.old'", :sudo
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
          if @file and (File.exists? @file or @file.is_uri?)
            cmd = %Q{qemu-img snapshot -U -l "#{@file}"}
            #out = `sudo #{cmd}` # sudo to access gluster://
            out = `#{cmd}`
            # E.g.:
            # Snapshot list:
            # ID        TAG                 VM SIZE                DATE       VM CLOCK
            # 1         test_snap0_off          0 B 2019-11-15 09:13:28   00:00:00.000
            # 2         test_snap1_off          0 B 2019-11-15 09:15:19   00:00:00.000
            # 3         test3off                0 B 2019-11-15 21:00:34   00:00:00.000
            # 4         test1on             257 MiB 2019-11-15 21:43:00   00:00:34.011
            # 5         restore_me          260 MiB 2019-11-15 22:09:33   00:27:04.415
            out.each_line do |line|
              if line =~ /^(\d+)\s+(\S|\S.*\S)\s+([\d\.]+\s+[TGMkiB]+)\s+(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)\s+(\d+:\d\d:\d\d\.\d+)\s*$/
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
          if @file and (File.exists? @file or @file.is_uri?)
            `sudo qemu-img info -U "#{@file}"`.each_line do |line|
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

