class OnBoard
  module Virtualization
    module QEMU
      class Config

        class Drive 

          # NOTE: directsync available on recent versions only 
          CACHE = %w{unsafe writeback writethrough directsync none}

          IF = %w{ide scsi sd mtd floppy pflash virtio} # from man page
          SUPPORTED_IFS = {
            'ide'     => 'ATA',
            'scsi'    => 'SCSI',
            'virtio'  => 'VirtIO',
          }

          class << self
            def disk_slots(opts={})
              defaults  = {
                :scsi     =>  {
                  :buses    =>    2,
                  :units    =>    2,
                },
                :virtio   =>  {
                  :indexes  =>    4,
                } 
              }
              opts = defaults.update(opts)
              slots = %w{ide0-hd0 ide0-hd1 ide1-hd1}
              0.upto(opts[:scsi][:buses] - 1) do |bus|
              end
            end
          end          

          attr_reader :config

          def initialize(config)
            @config = config
          end

          alias to_h config

          # Corresponding name in 'info block' output from QEMU Monitor
          def to_runtime_name
            name = "#{@config['if']}"
            case @config['if']
            when 'virtio'
              raise RuntimeError, "I cannot manage this: #{@config.inspect}" unless 
                  @config['index'] # Assumption to make the machinery work :-p
              name << @config['index'].to_s
              return name
            else
              name << @config['bus'].to_s
              case @config['media']
              when 'disk'
                name << '-hd'
              when 'cdrom'
                name << '-cd'
              else
                raise RuntimeError, "I cannot manage this: #{@config.inspect}"
              end
              name << @config['unit'].to_s
              return name
            end
          end

          def [](k) 
            @config[k]
          end

          def to_json(*a)
            @config.to_json(*a)
          end

        end

      end
    end
  end
end


