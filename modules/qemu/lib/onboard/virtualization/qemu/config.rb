gem 'uuid'

autoload :UUID, 'uuid'

class OnBoard
  module Virtualization
    module QEMU
      class Config

        class << self
          def http_params2argv(params, opts={}) 
            uuid = opts[:uuid] || UUID.generate
            return "-uuid #{uuid} -m 512 -vnc #{params['vnc']} -drive #{params['drive'][0]['file']},index=0 -daemonize -monitor unix:/var/run/qemu-#{uuid}.sock,server,nowait -pidfile /var/run/qemu-#{uuid}.pid"
          end
        end

        def initialize(h)
          if h[:http_params]
            @uuid = UUID.generate
            @argv = self.class.http_params2argv(h[:http_params], :uuid=>@uuid)
          else
            @uuid = h[:config]['uuid']
            @argv = h[:config]['argv']
          end
        end

        def to_h
          {
            'uuid' => @uuid,
            'argv' => @argv 
          }
        end

        def to_json(*a); to_h.to_json(*a); end

        def save
          yaml_file = File.join QEMU::CONFDIR, "#@uuid.yml" 
          File.open yaml_file, 'w' do |f|
            f.write YAML.dump export_data
          end
        end

      end
    end
  end
end
