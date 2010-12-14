class OnBoard
  module Service
    module RADIUS
      class Group

        class << self

          def setup
            @@conf      ||= RADIUS.read_conf
            @@chktable  ||= @@conf['group']['check']['table'].to_sym
            @@chkcols   ||= @@conf['group']['check']['columns'].symbolize_values
            @@rpltable  ||= @@conf['group']['reply']['table'].to_sym
            @@rplcols   ||= @@conf['group']['reply']['columns'].symbolize_values
            @@maptable  ||= @@conf['group']['usermap']['table']
            @@mapcols   ||= @@conf['group']['usermap']['columns']
          end

          def setup!
            @@conf = @@chktable = @@chkcols = @@rpltable = @@rplcols = nil
            setup
          end

          def get(params)
            setup
            column    = @@conf['check']['columns']['User-Name'].to_sym
            page      = params[:page].to_i 
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[@@chktable].select(column).group_by(column)
            users     = select.paginate(page, per_page).map do |h| 
              h[column].force_encoding 'utf-8'
            end

            {
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page,
              'users'       => users.map{|u| new(u)} 
            }
          end
        
        end

        attr_reader :name, :check, :reply

        def setup;  self.class.setup;   end
        def setup!; self.class.setup!;  end

        def initialize(username)
          @name             = username
        end

        def retrieve_attributes_from_db
          setup
          @check = RADIUS.db[@@chktable].where(
            @@chkcols['User-Name'] => @name
          ).to_a
          @reply = RADIUS.db[@@rpltable].where(
            @@chkcols['User-Name'] => @name
          ).to_a
        end

        def update_reply_attributes(params)
          params['reply'].each_pair do |attribute, value|
            RADIUS.db[@@rpltable].filter(
              @@rplcols['User-Name']  => @name,
              @@rplcols['Attribute']  => attribute
            ).delete
            next unless value =~ /\S/
            RADIUS.db[@@rpltable].insert(
              @@rplcols['User-Name']  => @name,
              @@rplcols['Attribute']  => attribute,
              @@rplcols['Operator']   => ':=',
              @@rplcols['Value']      => value
            )
          end
        end
        
        def update_check_attributes(params) # no passwords
          params['check'].each_pair do |attribute, value|
            # passwords are managed by #update_password
            next if attribute =~ /-Password$/ or attribute =~ /^Password-/
            # inerting User-Name attribute doesn't make sense: there's 
            # already @@chkcols['User-Name'] column
            next if attribute == 'User-Name'
            RADIUS.db[@@chktable].filter(
              @@chkcols['User-Name']  => @name,
              @@chkcols['Attribute']  => attribute
            ).delete
            next unless value =~ /\S/
            RADIUS.db[@@chktable].insert(
              @@chkcols['User-Name']  => @name,
              @@chkcols['Attribute']  => attribute,
              @@chkcols['Operator']   => ':=',
              @@chkcols['Value']      => value
            )
          end
        end

        def update_passwd(params)
          if params['check']['User-Password'] !=
              params['confirm']['check']['User-Password']
            raise PasswordsDoNotMatch, 'Passwords do not match!'
          end
          return unless params['check']['User-Password'] =~ /\S/
          # so an incorrect Password-Type would raise an exception
          encrypted_passwd = RADIUS.compute_password(
            :type             => params['check']['Password-Type'],
            :cleartext        => params['check']['User-Password']
          )
          RADIUS.db[@@chktable].filter(
            @@chkcols['User-Name']  => @name
          ).filter(
            @@chkcols['Attribute'].like '%-Password'
          ).delete
          RADIUS.db[@@chktable].insert(
            @@chkcols['User-Name']  => @name,
            @@chkcols['Attribute']  => params['check']['Password-Type'],
            @@chkcols['Operator']   => ':=',
            @@chkcols['Value']      => encrypted_passwd
          )
        end

        def update(params)
          update_passwd(params)
          update_check_attributes(params)
          update_reply_attributes(params)
        end

        #   user.find_attribute do |attrib, op, val|
        #     attrib =~ /-Password$/
        #   end
        #
        #   user.find_attribute do |attr, op, val|
        #     attrib == 'Auth-Type'
        #   end
        #
        #   user.find_attribute do |attr, op, val|
        #     attrib == 'Idle-Timeout' and val < 1800
        #   end
        #
        # Returns an Hash.
        #
        def find_attribute(tbl, &blk) 
          retrieve_attributes_from_db unless @check # @reply MIGHT be empty...
          case tbl
          when :check
            row = @check.find do |h| 
              blk.call( 
                       h[@@chkcols['Attribute']],
                       h[@@chkcols['Operator']],
                       h[@@chkcols['Value']],
                      )
            end
            return row ? row : nil
          when :reply
            row = @reply.find do |h| 
              blk.call( 
                       h[@@rplcols['Attribute']],
                       h[@@rplcols['Operator']],
                       h[@@rplcols['Value']],
                      )
            end
            return row ? row : nil
          else
            raise ArgumentError, "Valid tables are :check and :reply"
          end
        end

        def find_attribute_value_by_name(tbl, attrname)
          row = find_attribute tbl do |attrib, op, val|
            attrib == attrname
          end
          return nil unless row
          return case tbl
            when :check
              row[@@chkcols['Value']]
            when :reply
              row[@@rplcols['Value']]
          end
        end
        alias attribute find_attribute_value_by_name

        def password_type
          row = find_attribute :check do |attrib, op, val|
            attrib =~ /-Password$/ 
          end
          row ? row[@@chkcols['Attribute']] : nil
        end

        def auth_type
          find_attribute_value_by_name(:check, 'Auth-Type')
        end

        def to_h
          {
            :name  => @name,
            :check => @check,
            :reply => @reply,
          }
        end

        def to_json(*args)
          to_h.to_json(*args)
        end
        def to_yaml(*args)
          to_h.deep_rekey{|k|k.to_s}.to_yaml(*args)
        end

      end
    end
  end
end

