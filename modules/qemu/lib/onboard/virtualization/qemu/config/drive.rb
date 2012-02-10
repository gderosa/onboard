class OnBoard
  module Virtualization
    module QEMU
      class Config

        class Drive 

          def initialize(config)
            @config = config
          end

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

        end

      end
    end
  end
end


