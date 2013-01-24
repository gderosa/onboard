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
              FileUtils.mkdir_p File.join ROOTDIR, name
              filepath = "#{ROOTDIR}/#{name}/#{h['idx']}.#{fmt}"
              if File.exists? filepath
                FileUtils.mv filepath, "#{filepath}.old"
              end
              System::Command.run(
                  "qemu-img create -f #{fmt} '#{filepath}' #{size_str}", :raise_BadRequest) 
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
          if @file and File.exists? @file
            `qemu-img snapshot -l "#{@file}"`.each_line do |line|
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

      end
    end
  end
end

