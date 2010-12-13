require 'rack/utils'

require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      module Reply

        class << self

          def insert(params)
            conf      = RADIUS.read_conf
            table     = conf['reply']['table'].to_sym
            col       = conf['reply']['columns'].symbolize_values
            if RADIUS.db[table].where(
                col['User-Name'] => params['check']['User-Name'] ).any?
              raise UserAlreadyExists, "User '#{Rack::Utils::escape_html params['check']['User-Name']}' already exists!"
            end
            RADIUS.db[table].insert(
              col['User-Name']  => params['check']['User-Name'],
              col['Operator']   => ':=',
              col['Attribute']  => 'Reply-Message',
              col['Value']      => params['reply']['Reply-Message']
            )
          end

        end

      end
    end
  end
end 
