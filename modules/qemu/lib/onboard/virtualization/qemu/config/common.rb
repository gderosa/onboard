require 'fileutils'
require 'yaml'

require 'onboard/extensions/hash'

class OnBoard
  module Virtualization
    module QEMU
      class Config
        module Common
          CONFDIR         = File.join QEMU::CONFDIR, 'common'
          CONFFILE        = File.join CONFDIR, 'config.yml'
          DEFAULTCONFFILE = File.join ROOTDIR, 'etc/defaults/virtualization/qemu/common/config.yml'
          class << self
            def get
              unless File.exists? CONFFILE
                FileUtils.mkdir_p CONFDIR
                FileUtils.cp DEFAULTCONFFILE, CONFFILE
              end
              yaml_load = YAML.load File.read CONFFILE
              if yaml_load.is_a? Array
                return yaml_load[0]
              else
                return yaml_load
              end
            end
            def set(h)
              FileUtils.mkdir_p CONFDIR
              File.open CONFFILE, 'w' do |f|
                f.write YAML.dump h[:http_params].let_in('exe' => true)
              end
              QEMU.reset_capabilities
            end
          end
        end
      end
    end
  end
end


