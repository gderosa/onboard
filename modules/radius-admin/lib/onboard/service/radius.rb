require 'fileutils'
require 'facets/hash'
require 'sequel'

class OnBoard
  module Service
    module RADIUS
      
      autoload :DEFAULTS,     'onboard/service/radius/defaults'
      autoload :Accounting,   'onboard/service/radius/accounting'
      autoload :Check,        'onboard/service/radius/check'
      #autoload :Reply,        'onboard/service/radius/reply'
        # use User#update_reply_attributes instead, even on User creation
      autoload :Passwd,       'onboard/service/radius/passwd'
      autoload :User,         'onboard/service/radius/user'
      autoload :Group,        'onboard/service/radius/group'
      autoload :Name,         'onboard/service/radius/name'
      autoload :Signup,       'onboard/service/radius/signup'
      autoload :Terms,        'onboard/service/radius/terms'

      CONFFILE = File.join CONFDIR, 'current/radius.conf.yaml'

      class Conflict            < Conflict;     end
      class BadRequest          < BadRequest;   end
      class UserAlreadyExists   < Conflict;     end
      class GroupAlreadyExists  < Conflict;     end
      class PasswordsDoNotMatch < BadRequest;   end
      class EmptyPassword       < BadRequest;   end

      class << self
        def conf
          unless class_variable_defined? :@@conf and @@conf
            @@conf = read_conf
          end
          return @@conf
        end

        def read_conf
          if File.readable? CONFFILE
            DEFAULTS.deep_merge YAML.load(File.read CONFFILE)
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
            :password => conf['dbpass'],
            :encoding => 'utf8'
          ) 
          @@db.extension :pagination
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
