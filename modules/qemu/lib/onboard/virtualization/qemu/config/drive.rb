require 'facets/hash'

class OnBoard
  module Virtualization
    module QEMU
      class Config

        class Drive 

          # NOTE: directsync available on recent versions only 
          CACHE = %w{unsafe writeback writethrough directsync none}
          
          class << self
            
            def slot2h(slot)
              media = {'hd' => 'disk', 'cd' => 'cdrom'}
              case slot
              when /(ide|scsi)(\d+)-(hd|cd)(\d+)/
                {
                  'media' => media[$3],
                  'if'    => $1,
                  'bus'   => $2.to_i,
                  'unit'  => $4.to_i,
                }
              when /(virtio)(\d+)/
                {
                  'if'    => $1,
                  'index' => $2.to_i,
                }
              end
            end
            alias slot2data slot2h

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
              opts = defaults.deep_merge(opts)
              slots = %w{ide0-hd0 ide0-hd1 ide1-hd1}
              0.upto(opts[:scsi][:buses] - 1) do |bus|
                0.upto(opts[:scsi][:units] - 1) do |unit|
                  slots << %Q{scsi#{bus}-hd#{unit}}
                end
              end
              0.upto(opts[:virtio][:indexes] - 1) do |index|
                slots <<%Q{virtio#{index}} 
              end
              slots
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
          alias runtime_name to_runtime_name

          def [](k) 
            @config[k]
          end

          def []=(k, val) 
            @config[k] = val
          end

          def to_json(*a)
            @config.to_json(*a)
          end

        end

      end
    end
  end
end


