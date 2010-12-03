require 'fileutils'
require 'sequel'

class OnBoard
  module Service
    module RADIUS
      
      autoload :DEFAULTS,     'onboard/service/radius/defaults'
      autoload :Accounting,   'onboard/service/radius/accounting'
      autoload :Check,        'onboard/service/radius/check'
      autoload :Passwd,       'onboard/service/radius/passwd'

      CONFFILE = File.join CONFDIR, 'current/radius.conf.yaml'

      class Conflict            < RuntimeError; end
      class BadRequest          < RuntimeError; end
      class UserAlreadyExists   < Conflict;     end
      class PasswordsDoNotMatch < BadRequest;   end

      class << self
        def conf
          unless class_variable_defined? :@@conf and @@conf
            @@conf = read_conf
          end
          return @@conf
        end

        def read_conf
          if File.readable? CONFFILE
            DEFAULTS.update YAML.load(File.read CONFFILE)
          else
            DEFAULTS
          end
        end

        def update_conf!
          return (@@conf = read_conf)
        end

        def write_conf(h)
          unless Dir.exists? File.dirname CONFFILE
            FileUtils.mkdir_p File.dirname CONFFILE
          end
          File.open CONFFILE, 'w' do |f|
            f.write h.to_yaml
          end
        end

        def db
          @@db = db_connect unless 
              class_variable_defined? :@@db
          return @@db
        end

        def db_connect
          @@db = Sequel.connect( "mysql://#{conf['dbhost']}/#{conf['dbname']}",
            :user     => conf['dbuser'],
            :password => conf['dbpass']
          ) 
        end

        def db_disconnect
          @@db.disconnect if
              class_variable_defined? :@@db and @@db
        end

        def db_reconnect
          db_disconnect
          db_connect
        end

        def compute_password(h)
          RADIUS::Passwd.new(h).to_s 
        end
      end

    end
  end
end
