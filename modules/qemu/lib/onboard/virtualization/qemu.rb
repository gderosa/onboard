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
            # TODO: DRY
            if params['start'] and params['start']['uuid']
              vm = all.find{|x| x.uuid == params['start']['uuid']} 
              vm.start
            end
            if params['start_paused'] and params['start_paused']['uuid']
              vm = all.find{|x| x.uuid == params['start_paused']['uuid']}
              vm.start_paused
            end
            if params['pause'] and params['pause']['uuid']
              vm = all.find{|x| x.uuid == params['pause']['uuid']}
              vm.pause
            end
            if params['resume'] and params['resume']['uuid']
              vm = all.find{|x| x.uuid == params['resume']['uuid']}
              vm.resume
            end
          end
        end

      end

    end
  end
end
