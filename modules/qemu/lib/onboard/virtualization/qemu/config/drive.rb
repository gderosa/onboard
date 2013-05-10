require 'facets/hash'
require 'onboard/extensions/kernel'

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
                  :units    =>    4,
                },
                :virtio   =>  {
                  :indexes  =>    8,
                } 
              }
              opts = defaults.deep_merge(opts)
              slots = %w{ide0-hd0 ide0-hd1 ide1-hd1}
                  # ide1-hd0'slot is hold by CD/DVD drive,
                  # named ide1-cd0 actually.
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
            cannot_guess_from = "Cannot guess runtime/Monitor name from these Drive data"
            return unless @config['if']
            name = "#{@config['if']}"
            case @config['if']
            when 'virtio'
              warn "#{cannot_guess_from}: #{@config.inspect}" unless 
                  xor( @config['index'], @config['unit'] )
              name << (@config['index'] || @config['unit']).to_s
              return name
            else
              name << @config['bus'].to_s
              case @config['media']
              when 'disk'
                name << '-hd'
              when 'cdrom'
                name << '-cd'
              else
                warn "#{cannot_guess_from}: #{@config.inspect}"
              end
              name << @config['unit'].to_s
              return name
            end
          end
          alias runtime_name to_runtime_name

          def img_info
            img = QEMU::Img.new :drive_config => @config
            img.info
          end

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


