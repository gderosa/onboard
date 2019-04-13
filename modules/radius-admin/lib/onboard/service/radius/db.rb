class OnBoard
  module Service
    module RADIUS
      module Db
        class << self

          # Methods that should be here, but are actually defined in ../radius.rb .
          # The following aliases allow future code to use a cleaner API, e.g.:
          #
          #   Service::RADIUS::Db.connect
          #
          # Also, they are here to make current code a bit more readable...
          #
          def connect;    RADIUS.db_connect;    end
          def disconnect; RADIUS.db_disconnect; end
          def reconnect;  RADIUS.db_reconnect;  end

          def reset_data(params)
            tables = []
            if params['resetdata']
              if params['resetdata']['default'] =~ /on|yes|true/
                tables += [
                  RADIUS.conf['terms_accept']['table'], # has FOREIGN KEYs
                  RADIUS.conf['user']['personal']['table'],
                  RADIUS.conf['user']['check']['table'],
                  RADIUS.conf['user']['reply']['table'],
                  RADIUS.conf['group']['check']['table'],
                  RADIUS.conf['group']['reply']['table'],
                  RADIUS.conf['group']['usermap']['table'],
                  RADIUS.conf['terms_accept']['table']
                ]
              end
              if params['resetdata']['accounting'] =~ /on|yes|true/
                tables += [
                  RADIUS.conf['accounting']['table']
                ]
              end
              if params['resetdata']['terms'] =~ /on|yes|true/
                tables += [
                  RADIUS.conf['terms']['table']
                ]
              end
            end
            tables.each do |table|
              RADIUS.db[table.to_sym].delete
            end

            Service::RADIUS::User.delete_all_attachments if params['resetdata']['default']

            tables
          end
          def format_error_msg(e, opts={})
            default_opts = {:check_your_config_msg => true}
            opts = default_opts.merge opts
            if opts[:check_your_config_msg]
              return "#{e}\nCheck your RADIUS Database configuration!"
            else
              return e
            end
          end
        end
      end
    end
  end
end
