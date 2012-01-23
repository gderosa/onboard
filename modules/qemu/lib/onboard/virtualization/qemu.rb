require 'yaml'
require 'json'

require 'uuid'

require 'onboard/virtualization/qemu/config'
require 'onboard/virtualization/qemu/instance'

class OnBoard
  module Virtualization
    module QEMU
      
      class << self
        def get_all
          ary = []
          Dir.glob "#{CONFDIR}/*.yml" do |file|
            config = Config.new(:config => YAML.load(File.read file)) 
            ary << Instance.new(config)
          end
          return ary
        end
      end

    end
  end
end
