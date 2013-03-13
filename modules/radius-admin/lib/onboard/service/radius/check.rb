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
            i18n = params[:i18n]
            if params['check']['User-Password'] != params['confirm']['check']['User-Password']
              if i18n
                raise PasswordsDoNotMatch, i18n.password.do_not_match.capitalize
              else
                raise PasswordsDoNotMatch, 'Passwords do not match!'
              end
            end
            if RADIUS.db[@@table].where(
                @@columns['User-Name'] => params['check']['User-Name'] ).any?
              if i18n
                raise UserAlreadyExists, "#{i18n.radius.user.registered.already.capitalize}: #{params['check']['User-Name']}."
              else
                raise UserAlreadyExists, "User '#{params['check']['User-Name']}' already exists!"
              end
            end
            
            validate_empty_password(params) # raises exception if appropriate

            Name.validate params['check']['User-Name'], :i18n => i18n

            # All is ok, proceed.
            #
            # First, insert a dummy attribute into check table, which is
            # useful to create an attribute-less user: this may make sense
            # for a number of reasons, for example a "stub" user which will
            # be configured later (and of course won't be authorized right 
            # now), or for a user who will be authenicated only on a 
            # per-group basis.

            insert_dummy_attributes(params)

            # Now, the "real" attributes.

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

          def insert_dummy_attributes(params)
            # In fact, there's no need to explicitly insert 'User-Name',
            # because there's already a @@columns['User-Name'] column.
            # For the rationale of this method, read comments inside 
            # the insert method.
            RADIUS.db[@@table].insert(
              @@columns['User-Name']  => params['check']['User-Name'],
              @@columns['Operator']   => ':=',
              @@columns['Attribute']  => 'User-Name',
              @@columns['Value']      => params['check']['User-Name']
            )
          end

          # Accept empty passwords only with Auth-Type == Reject or Accept.
          # Raise an exception otherwise.
          def validate_empty_password(params)
            i18n = params[:i18n] # params mixes http/form and non-http/form 
            if  ['', nil].include? params['check']['User-Password'] and
                ['', nil].include? params['check']['Auth-Type']     and not
                ['', nil].include? params['check']['Password-Type']
              if i18n
                raise EmptyPassword, "#{i18n.invalid_or_missing_info(1).capitalize}: Password"
              else
                raise EmptyPassword, 'Cannot accept an empty password if password authentication is enabled.'
              end
            end
          end
          

        end

      end
    end
  end
end 
