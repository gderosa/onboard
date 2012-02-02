require 'yaml'
require 'uuid'

class OnBoard
  module Virtualization
    module QEMU

      # TODO: do not hardcode so badly 
      FILESDIR = '/home/onboard/files'

      autoload :Config,   'onboard/virtualization/qemu/config'
      autoload :Instance, 'onboard/virtualization/qemu/instance'
      autoload :Img,      'onboard/virtualization/qemu/img'
      
      class << self

        def get_all
          ary = []
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            config = Config.new(:config => YAML.load(File.read file)) 
            ary << Instance.new(config)
          end
          return ary
        end

        def manage(h)
          all = get_all
          if h[:http_params]
            params = h[:http_params]
            if params['start'] and params['start']['uuid']
              vm = all.find{|x| x.uuid == params['start']['uuid']} 
              vm.start
            end
          end
        end

      end

    end
  end
end
