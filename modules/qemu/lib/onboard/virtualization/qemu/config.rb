gem 'uuid'

autoload :UUID, 'uuid'

class OnBoard
  module Virtualization
    module QEMU
      class Config

        autoload :Common, 'onboard/virtualization/qemu/config/common'

        class << self

          def absolute_path(path)
            return path if path =~ /^\//
            return File.join FILESDIR, path
          end

        end

        attr_reader :uuid, :cmd

        def [](k)
          @cmd['opts'][k] 
        end

        def initialize(h)
          if h[:http_params]
            @uuid = UUID.generate # creation from POST
            @cmd  = {
              #'exe'   => 'kvm',
              'opts'  => {
                '-enable-kvm' => true,
                '-uuid'       => @uuid,
                '-name'       => h[:http_params]['name'],
                '-m'          => h[:http_params]['m'].to_i,
                '-vnc'        => h[:http_params]['vnc'],
                #'-drive'     => [
                #  {
                #    'file'     => h[:http_params]['disk'], 
                #    'media'    => 'disk',
                #    'index'    => 0
                #  }
                #],
                '-daemonize'  => true,
                '-monitor'    => {
                  'unix'        => "#{VARRUN}/qemu-#{uuid_short}.sock",
                  'server'      => true,
                  'nowait'      => true
                },
                '-pidfile'    => "#{VARRUN}/qemu-#{uuid_short}.pid"
              }
            }
            if h[:http_params]['disk'] =~ /\S/
              @cmd['opts']['-drive'] ||= []
              @cmd['opts']['-drive'] << {
                'file'  => self.class.absolute_path(h[:http_params]['disk']),
                'media' => 'disk',
                'index' => 0
              }
            end
            if h[:http_params]['cdrom'] =~ /\S/
              @cmd['opts']['-drive'] ||= []
              @cmd['opts']['-drive'] << {
                'file'  => self.class.absolute_path(h[:http_params]['cdrom']),
                'media' => 'cdrom',
                'index' => 1
              }
            end
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
