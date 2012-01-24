gem 'uuid'

autoload :UUID, 'uuid'

class OnBoard
  module Virtualization
    module QEMU
      class Config

        class << self
=begin
          def http_params2argv(params, opts={}) 
            uuid = opts[:uuid] || UUID.generate
            return "-uuid #{uuid} -m 512 -vnc #{params['vnc']} -drive #{params['drive'][0]['file']},index=0 -daemonize -monitor unix:/var/run/qemu-#{uuid}.sock,server,nowait -pidfile /var/run/qemu-#{uuid}.pid"
          end
=end
        end

        attr_reader :uuid, :cmd

        def initialize(h)
          if h[:http_params]
            @uuid = UUID.generate # creation from POST
            @cmd  = {
              'exe'   => 'kvm',
              'opts'  => {
                '-uuid'     => @uuid,
                '-name'     => h[:http_params]['name'],
                '-m'        => 512,
                '-vnc'      => h[:http_params]['vnc'],
                '-drive'    => [
                  {
                    'file'    => h[:http_params]['drive'][0]['file'],
                    'media'   => 'disk',
                    'index'   => 0
                  }
                ],
                '-daemonize'  => true,
                '-monitor'    => {
                  'unix'        => "/var/run/qemu-#{@uuid}.sock",
                  'server'      => true,
                  'nowait'      => true
                },
                '-pidfile'    => "/var/run/qemu-#{@uuid}.pid"
              }
            }
          else
            @uuid = h[:config]['uuid']
            @cmd  = h[:config]['cmd']
          end
        end

        def uuid_short
          @uuid.split('-')[0] 
        end

        def opts
          @cmd['opts']
        end

        def to_h
          {
            'uuid'  => @uuid,
            'cmd'   => @cmd 
          }
        end

        def to_json(*a); to_h.to_json(*a); end

        def save
          yaml_file = File.join QEMU::CONFDIR, "#@uuid.yml" 
          File.open yaml_file, 'w' do |f|
            f.write YAML.dump to_h 
          end
        end

      end
    end
  end
end
