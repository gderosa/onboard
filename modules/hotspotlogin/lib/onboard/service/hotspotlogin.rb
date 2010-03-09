autoload :YAML, 'yaml'

require 'onboard/system/process'

class OnBoard
  module Service
    class HotSpotLogin

      CONFFILE = File.join CONFDIR, 'current/hotspotlogin.conf.yaml'
      DEFAULT_CONFFILE = File.join CONFDIR, 'defaults/hotspotlogin.conf.yaml'

      # this OnBoard module cannot handle more than one process
      class MultipleInstances < RuntimeError; end

      def self.running?
        true
      end

      def self.data
        {
          'conf' => YAML.load(File.read(CONFFILE)),
          'running' => running?
        }
      end

    end
  end
end

