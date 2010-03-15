require 'sequel'

class OnBoard
  module Service
    module RADIUS
      
      autoload :Accounting, 'onboard/service/radius/accounting'

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

      def self.connect_db
        conf = read_conf
        @@db = Sequel.connect( "mysql://#{conf['dbhost']}/#{conf['dbname']}",
          :user     => conf['dbuser'],
          :password => conf['dbpass']
        ) unless class_variable_defined? :@@db
      end

      def self.db
        @@db = connect_db unless class_variable_defined? :@@db
        return @@db
      end

    end
  end
end
