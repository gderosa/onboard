require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'
require 'onboard/extensions/sequel/dataset'

class OnBoard
  module Service
    module RADIUS
      class Group

        class << self

          def setup
            @@conf      ||= 
                RADIUS.read_conf
            @@chktable  ||= 
                @@conf['group']['check']['table'].to_sym
            @@chkcols   ||= 
                @@conf['group']['check']['columns'].symbolize_values
            @@rpltable  ||= 
                @@conf['group']['reply']['table'].to_sym
            @@rplcols   ||= 
                @@conf['group']['reply']['columns'].symbolize_values
            @@maptable  ||= 
                @@conf['group']['usermap']['table'].to_sym
            @@mapcols   ||= 
                @@conf['group']['usermap']['columns'].symbolize_values
          end

          def setup!
            @@conf = 
                @@chktable = @@chkcols = 
                @@rpltable = @@rplcols = 
                @@maptable = @@mapcols = nil
            setup
          end

          def get(params)
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            setup
            q_usergroup   =  
                RADIUS.db[@@maptable].select(
                    @@mapcols['Group-Name'] => :groupname) 
            q_groupcheck  =
                RADIUS.db[@@chktable].select(
                    @@chkcols['Group-Name'] => :groupname) 
            q_groupreply  =
                RADIUS.db[@@rpltable].select(
                    @@rplcols['Group-Name'] => :groupname)
            q_union       = q_usergroup | q_groupcheck | q_groupreply
            q_paginate    = q_union.paginate(page, per_page)
            groupnames    = q_paginate.group_by(:groupname).map(:groupname)
            {
              'total_items' => q_union.count,
              'page'        => page,
              'per_page'    => per_page,
              'groups'      => groupnames.map{|u| new(u)} 
            }
          end

          def insert(params)
            setup
            if params['check']['Group-Password'] !=
                params['confirm']['check']['Group-Password']
              raise PasswordsDoNotMatch, 'Passwords do not match!'
            end
            if RADIUS.db[@@chktable].where(
                @@chkcols['Group-Name'] => params['check']['Group-Name'] ).any?
              raise GroupAlreadyExists, "Group '#{params['check']['Group-Name']}' already exists!"
            end
            if  ['', nil].include? params['check']['Group-Password'] and
                ['', nil].include? params['check']['Auth-Type']     and not
                ['', nil].include? params['check']['Password-Type']
              raise EmptyPassword, 'Cannot accept an empy password if group authentication is Enabled and a Password Type has been set.'
            end

            # All is ok, proceed.
            #
            # First, insert a dummy attribute into check table, which may be
            # useful if you want to create an attribute-less group...

            insert_dummy_attributes(params)

            # Now, the "real" attributes.

            if params['check']['Password-Type'] =~ /\S/
              RADIUS.db[@@chktable].insert(
                @@chkcols['Group-Name'] => params['check']['Group-Name'],
                # Use '=' operator instead of ':=', so if an attribute
                # is already set for the specific user, it will take 
                # precedence.
                @@chkcols['Operator']   => '=',
                @@chkcols['Attribute']  => params['check']['Password-Type'],
                @@chkcols['Value']      => RADIUS.compute_password(
                  :type             => params['check']['Password-Type'],
                  :cleartext        => params['check']['Group-Password']
                ),
              )
            end
            RADIUS.db[@@chktable].insert(
              @@chkcols['Group-Name'] => params['check']['Group-Name'],
              @@chkcols['Operator']   => '=',
              @@chkcols['Attribute']  => 'Auth-Type',
              @@chkcols['Value']      => params['check']['Auth-Type'],
            ) if params['check']['Auth-Type'] =~ /\S/
          end

          def insert_dummy_attributes(params)
            # In fact, there's no need to explicitly insert 'Group',
            # because there's already a @@columns['User-Name'] column.
            # For the rationale of this method, read comments inside
            # the insert method.
            RADIUS.db[@@chktable].insert(
              @@chkcols['Group-Name'] => params['check']['Group-Name'],
              @@chkcols['Operator']   => '=',
              @@chkcols['Attribute']  => 'Group',
              @@chkcols['Value']      => params['check']['Group-Name']
            )
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
            @@chkcols['Group-Name'] => @name
          ).to_a
          @reply = RADIUS.db[@@rpltable].where(
            @@chkcols['Group-Name'] => @name
          ).to_a
        end

        def found?
          @check.length + @reply.length > 0
        end

        def update_reply_attributes(params)
          params['reply'].each_pair do |attribute, value|
            RADIUS.db[@@rpltable].filter(
              @@rplcols['Group-Name'] => @name,
              @@rplcols['Attribute']  => attribute
            ).delete
            next unless value =~ /\S/
            RADIUS.db[@@rpltable].insert(
              @@rplcols['Group-Name'] => @name,
              @@rplcols['Attribute']  => attribute,
              @@rplcols['Operator']   => '=',
              @@rplcols['Value']      => value
            )
          end
        end
        
        def update_check_attributes(params) # no passwords
=begin
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
=end
        end

        def update_passwd(params)
=begin
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
=end
        end

        def update(params)
=begin
          update_passwd(params)
          update_check_attributes(params)
          update_reply_attributes(params)
=end
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
=begin
          row = find_attribute :check do |attrib, op, val|
            attrib =~ /-Password$/ 
          end
          row ? row[@@chkcols['Attribute']] : nil
=end
        end

        def auth_type
          find_attribute_value_by_name(:check, 'Auth-Type')
        end

        def to_h
=begin
          {
            :name  => @name,
            :check => @check,
            :reply => @reply,
          }
=end
        end

        def to_json(*args)
          #to_h.to_json(*args)
        end
        def to_yaml(*args)
          #to_h.deep_rekey{|k|k.to_s}.to_yaml(*args)
        end

      end
    end
  end
end

