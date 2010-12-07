require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      module Check

        class << self

          def get(params)
            conf      = RADIUS.read_conf
            table     = conf['check']['table'].to_sym
            columns   = conf['check']['columns']
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[table].select(
              *columns.symbolize_all.values
            ).order_by columns['User-Name'].to_sym
            {
              'columns'     => columns,
              'rows'        => select.paginate(page, per_page).to_a,
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page
            }
          end

        
          def insert(params)
            conf      = RADIUS.read_conf
            table     = conf['check']['table'].to_sym
            col       = conf['check']['columns'].symbolize_values
            if params['check']['User-Password'] != 
                params['confirm']['check']['User-Password']
              raise PasswordsDoNotMatch, 'Passwords do not match!'
            end
            if RADIUS.db[table].where(
                col['User-Name'] => params['check']['User-Name'] ).any?
              raise UserAlreadyExists, "User '#{params['check']['User-Name']}' already exists!"
            end
            RADIUS.db[table].insert(
              col['User-Name']  => params['check']['User-Name'],
              col['Operator']   => ':=',
              col['Attribute']  => params['check']['Password-Type'],
              col['Value']      => RADIUS.compute_password(
                :type             => params['check']['Password-Type'],
                :cleartext        => params['check']['User-Password']
              ),
            )
          end

        end

      end
    end
  end
end 
