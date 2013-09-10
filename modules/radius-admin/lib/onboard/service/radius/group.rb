require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'
require 'onboard/extensions/sequel'

class OnBoard
  module Service
    module RADIUS
      class Group

        class << self

          # TODO: rails-like cattr_accessor's ?
          def method_missing(id, *args)
            class_variable_get :"@@#{id}" 
          end

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
            page            = params[:page].to_i
            per_page        = params[:per_page].to_i
            setup
            q_usergroup     =  
                RADIUS.db[@@maptable].select(
                    Sequel.as(@@mapcols['Group-Name'], :groupname)
                ) 
            q_groupcheck    =
                RADIUS.db[@@chktable].select(
                    Sequel.as(@@chkcols['Group-Name'], :groupname)
                ) 
            q_groupreply    =
                RADIUS.db[@@rpltable].select(
                    Sequel.as(@@rplcols['Group-Name'], :groupname)
                )
            q_union         = q_usergroup | q_groupcheck | q_groupreply
            q_paginate      = q_union.paginate(page, per_page)
            groupnames      = 
                q_paginate.group_by(:groupname).map(:groupname).map do |name|
                  name.force_encoding 'utf-8'
                end
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

            validate_empty_password(params) # raises exception if appropriate

            Name.validate params['check']['Group-Name']

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
            # because there's already a @@columns['Group-Name'] column.
            # For the rationale of this method, read comments inside
            # the insert method.
            RADIUS.db[@@chktable].insert(
              @@chkcols['Group-Name'] => params['check']['Group-Name'],
              @@chkcols['Operator']   => '=',
              @@chkcols['Attribute']  => 'Group',
              @@chkcols['Value']      => params['check']['Group-Name']
            )
          end

          # Accept empty passwords only with Auth-Type == Reject or Accept.
          # Raise an exception otherwise.
          def validate_empty_password(params)
            if  ['', nil].include? params['check']['Group-Password'] and
                ['', nil].include? params['check']['Auth-Type']     and not
                ['', nil].include? params['check']['Password-Type']
              raise EmptyPassword, 'Cannot accept an empy password if group password authentication is enabled.'
            end
          end

        end

        attr_reader :name, :check, :reply

        def setup;  self.class.setup;   end
        def setup!; self.class.setup!;  end

        def initialize(groupname)
          @name = groupname
          @check = []
          @reply = []
        end

        def retrieve_attributes_from_db
          setup

          @check = RADIUS.db[@@chktable].select(
            *Sequel.aliases(@@chkcols.invert)
          ).where(
            @@chkcols['Group-Name'] => @name
          ).to_a

          @reply = RADIUS.db[@@rpltable].select(
            *Sequel.aliases(@@rplcols.invert)
          ).where(
            @@chkcols['Group-Name'] => @name
          ).to_a
        end

        # Group members, as opposed to group attributes, might be thousands,
        # so pagination is necessary - and holding (paginated) results
        # into an instance variable does not make much sense.
        def get_members(params)
          setup
          page          = params[:page].to_i
          per_page      = params[:per_page].to_i
          q_members     = RADIUS.db[@@maptable].where(
            @@mapcols['Group-Name'] => @name
          ).order_by @@mapcols['User-Name']
          member_rows   = q_members.paginate(page, per_page)
          member_names  = member_rows.map(@@mapcols['User-Name']).map do |s| 
            s.force_encoding 'utf-8'
          end
          {
            'total_items' => q_members.count,
            'page'        => page,
            'per_page'    => per_page,
            'users'       => member_names.map{|u| User.new(u)} 
          }
        end

        def found?
          return true if 
              (@check and @check.any?) or 
              (@reply and @reply.any?) 

          return true if RADIUS.db[@@maptable].where(
              @@mapcols['Group-Name'] => @name
          ).any?

          return true if RADIUS.db[@@chktable].where(
              @@chkcols['Group-Name'] => @name
          ).any?

          return true if RADIUS.db[@@rpltable].where(
              @@rplcols['Group-Name'] => @name
          ).any?

          return false
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
          params['check'].each_pair do |attribute, value|
            # passwords are managed by #update_password
            next if attribute =~ /-Password$/ or attribute =~ /^Password-/
            RADIUS.db[@@chktable].filter(
              @@chkcols['Group-Name']  => @name,
              @@chkcols['Attribute']  => attribute
            ).delete
            next unless value =~ /\S/
            RADIUS.db[@@chktable].insert(
              @@chkcols['Group-Name']  => @name,
              @@chkcols['Attribute']  => attribute,
              @@chkcols['Operator']   => '=', # so user attr w/ ':=' prevail
              @@chkcols['Value']      => value
            )
          end
        end

        def update_passwd(params)
          if params['check']['Group-Password'] !=
              params['confirm']['check']['Group-Password']
            raise PasswordsDoNotMatch, 'Passwords do not match!'
          end
          validate_empty_password(params) 
          if params['check']['Password-Type'] =~ /\S/
            return unless params['check']['Group-Password'] =~ /\S/
            # so an incorrect Password-Type would raise an exception
            encrypted_passwd = RADIUS.compute_password(
              :type             => params['check']['Password-Type'],
              :cleartext        => params['check']['Group-Password']
            )
          end
          RADIUS.db[@@chktable].filter(
            @@chkcols['Group-Name']  => @name
          ).filter(
            Sequel.like(@@chkcols['Attribute'], '%-Password') # Sequel.ilike ?
          ).delete
          if params['check']['Password-Type'] =~ /\S/
            RADIUS.db[@@chktable].insert(
              @@chkcols['Group-Name']  => @name,
              @@chkcols['Attribute']  => params['check']['Password-Type'],
              @@chkcols['Operator']   => ':=',
              @@chkcols['Value']      => encrypted_passwd
            )
          end
        end

        def add_member(member, priority=1)
          if RADIUS.db[@@maptable].filter(
            @@mapcols['Group-Name'] => @name,
            @@mapcols['User-Name']  => member
          ).any?
            raise UserAlreadyExists
          else
            RADIUS::Name.validate member
            RADIUS.db[@@maptable].insert(
              @@mapcols['Group-Name'] => @name,
              @@mapcols['User-Name']  => member,
              @@mapcols['Priority']   => priority
            )
          end
        end

        def remove_member(member)
          RADIUS.db[@@maptable].filter(
            @@mapcols['Group-Name'] => @name,
            @@mapcols['User-Name']  => member
          ).delete
        end

        # TODO: DRY
        def insert_fall_through_if_not_exists
          setup
          unless @reply.find do |row|
            row[:Attribute] == 'Fall-Through' and
            row[:Operator]  =~ /=$/           and
            row[:Value]     =~ /yes/i
          end
            LOGGER.info "radius-admin: I am inserting Fall-Through reply attribute for group #{@name}!"
            RADIUS.db[@@rpltable].insert(
              @@rplcols['Group-Name'] => @name,
              @@rplcols['Operator']   => '=',
              @@rplcols['Attribute']  => 'Fall-Through',
              @@rplcols['Value']      => 'yes'
            )
          end
        end

        def update(params)
          if params['update_members']
            alread_exist = []
            new_members = 
                params['add_members'].split(/[ ,;\r\n]+/m).reject{|s| s.empty?}
            new_members.each do |member|
              begin
                add_member member
              rescue UserAlreadyExists
                alread_exist << member
              end
            end
            if alread_exist.any? 
              raise Warning, "The folowing users are already part of group #{@name} : #{alread_exist.join(', ')}."
            end

            if params['remove'].respond_to? :each_pair
              params['remove'].each_pair do |name, value|
                if %w{on yes 1}.include? value
                  remove_member name
                end
              end
            end

          else # update attributes by default
            update_passwd(params)
            update_check_attributes(params)
            update_reply_attributes(params)
          end
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
          case tbl
          when :check
            row = @check.find do |h| 
              blk.call(h[:Attribute], h[:Operator], h[:Value])
            end
            return row ? row : nil
          when :reply
            row = @reply.find do |h| 
              blk.call(h[:Attribute], h[:Operator], h[:Value])
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
          return row[:Value]
        end
        alias attribute find_attribute_value_by_name

        def password_type
          row = find_attribute :check do |attrib, op, val|
            attrib =~ /-Password$/ 
          end
          row ? row[:Attribute] : nil
        end

        def auth_type
          find_attribute_value_by_name(:check, 'Auth-Type')
        end

        def validate_empty_password(params)
          # if password type is not being changed, leaving the password
          # fields blank simply means "leave the password unchanged". 
          if password_type != params['check']['Password-Type']
            self.class.validate_empty_password(params)
          end
        end

        def delete!
          setup
          RADIUS.db.transaction do
            RADIUS.db[@@maptable].where(
              @@mapcols['Group-Name'] => @name
            ).delete
            RADIUS.db[@@chktable].where(
              @@chkcols['Group-Name'] => @name
            ).delete
            RADIUS.db[@@rpltable].where(
              @@rplcols['Group-Name'] => @name
            ).delete
          end
        end

        def to_h
          {
            :name     => @name,
            :check    => @check,
            :reply    => @reply,
            :members  => @members
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

