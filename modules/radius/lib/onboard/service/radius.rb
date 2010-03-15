class OnBoard
  module Service
    module RADIUS
      CONFFILE = File.join CONFDIR, 'current/radius.conf.yaml'

      def self.read_conf
        if File.readable? CONFFILE
          YAML.load(File.read CONFFILE)
        else
          {}
        end
      end

      def self.write_conf(h)
        File.open CONFFILE, 'w' do |f|
          f.write h.to_yaml
        end
      end

    end
  end
end
