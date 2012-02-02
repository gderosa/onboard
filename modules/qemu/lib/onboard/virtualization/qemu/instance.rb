require 'json'

class OnBoard
  module Virtualization
    module QEMU
      class Instance

        attr_reader :config

        def initialize(config)
          @config = config
        end

        def uuid;       @config.uuid;       end
        def uuid_short; @config.uuid_short; end

        def to_h
          {'config' => @config.to_h}
        end

        def to_json(*a)
          to_h.to_json(*a)
        end

        def start
          opts = @config.cmd['opts'] 
          exe = Config::Common.get['exe'] 
          cmdline = ''
          cmdline << %Q{#{exe} } 
          %w{
            -uuid 
            -name 
            -m
            -vnc
            -pidfile
          }.each do |o|
            cmdline << o << ' ' << opts[o] << ' ' if opts[o] =~ /\S/  
          end
          cmdline << '-daemonize' << ' ' if opts['-daemonize'] 
          if opts['-monitor']
            if opts['-monitor']['unix']
              unix_args = []
              unix_args << %Q{unix:"#{opts['-monitor']['unix']}"} 
              unix_args << 'server' if opts['-monitor']['server']
              unix_args << 'nowait' if opts['-monitor']['nowait']
              cmdline << '-monitor ' << unix_args.join(',') << ' '
            end 
          end
          if opts['-drive'].respond_to? :each
            opts['-drive'].each do |d|
              drive_args = []
              drive_args << %Q{file="#{d['file']}"} 
              drive_args << %Q{media=#{d['media']}} 
              drive_args << %Q{index=#{d['index']}} if 
                  d['index'] =~ /\S/
              cmdline << '-drive ' << drive_args.join(',') << ' '
            end
          end
          puts cmdline
        end

      end
    end
  end
end
