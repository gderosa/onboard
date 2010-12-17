require 'rack/utils'

require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      module Check

        class << self

          def setup
            @@conf    ||= RADIUS.read_conf
            @@table   ||= @@conf['user']['check']['table'].to_sym
            @@columns ||= @@conf['user']['check']['columns'].symbolize_values
          end

          def setup!
            @@conf = @@table = @@columns = nil
          end

          def get(params)
            setup
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[@@table].select(
              *@@columns.values
            ).order_by @@columns['User-Name']
            {
              #'columns'     => columns,
              'rows'        => select.paginate(page, per_page).to_a,
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page
            }
          end
  
        
          def insert(params)
            setup
            if params['check']['User-Password'] != 
                params['confirm']['check']['User-Password']
              raise PasswordsDoNotMatch, 'Passwords do not match!'
            end
            if RADIUS.db[@@table].where(
                @@columns['User-Name'] => params['check']['User-Name'] ).any?
              raise UserAlreadyExists, "User '#{params['check']['User-Name']}' already exists!"
            end
            if params['check']['Password-Type'] =~ /\S/
              RADIUS.db[@@table].insert(
                @@columns['User-Name']  => params['check']['User-Name'],
                @@columns['Operator']   => ':=',
                @@columns['Attribute']  => params['check']['Password-Type'],
                @@columns['Value']      => RADIUS.compute_password(
                  :type             => params['check']['Password-Type'],
                  :cleartext        => params['check']['User-Password']
                ),
              )
            end
            RADIUS.db[@@table].insert(
              @@columns['User-Name']  => params['check']['User-Name'],
              @@columns['Operator']   => ':=',
              @@columns['Attribute']  => 'Auth-Type',
              @@columns['Value']      => params['check']['Auth-Type'],
            ) if params['check']['Auth-Type'] =~ /\S/
          end

        end

      end
    end
  end
end 
