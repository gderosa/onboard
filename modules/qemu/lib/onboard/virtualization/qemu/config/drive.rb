class OnBoard
  module Virtualization
    module QEMU
      class Config

        class Drive 

          attr_reader :config

          def initialize(config)
            @config = config
          end

          alias to_h config

          # Corresponding name in 'info block' output from QEMU Monitor
          def to_runtime_name
            name = "#{@config['if'] or 'ide'}#{@config['bus']}-"
            case @config['media']
            when 'disk'
              name << 'hd'
            when 'cdrom'
              name << 'cd'
            else
              raise RuntimeError, "I cannot manage this: #{@config.inspect}"
            end
            name << @config['unit'].to_s
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


