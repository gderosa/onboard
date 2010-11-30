require 'fileutils'
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
        unless Dir.exists? File.dirname CONFFILE
          FileUtils.mkdir_p File.dirname CONFFILE
        end
        File.open CONFFILE, 'w' do |f|
          f.write h.to_yaml
        end
      end

      def self.db
        @@db = db_connect unless 
            class_variable_defined? :@@db
        return @@db
      end

      def self.db_connect
        conf = read_conf
        @@db = Sequel.connect( "mysql://#{conf['dbhost']}/#{conf['dbname']}",
          :user     => conf['dbuser'],
          :password => conf['dbpass']
        ) 
      end

      def self.db_disconnect
        @@db.disconnect if
            class_variable_defined? :@@db and @@db
      end

      def self.db_reconnect
        db_disconnect
        db_connect
      end

    end
  end
end
