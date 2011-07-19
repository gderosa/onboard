require 'fileutils'
require 'facets/hash'
require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/sequel/dataset'
require 'onboard/extensions/object/deep'
require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      class User

        UPLOADS = File.join RADIUS::UPLOADS, 'users'

        class << self

          def setup
            @@conf      ||= RADIUS.read_conf
            @@chktable  ||= @@conf['user']['check']['table'].to_sym
            @@chkcols   ||= @@conf['user']['check']['columns'].symbolize_values
            @@rpltable  ||= @@conf['user']['reply']['table'].to_sym
            @@rplcols   ||= @@conf['user']['reply']['columns'].symbolize_values
            @@perstable ||= @@conf['user']['personal']['table'].to_sym
            @@perscols  ||= 
                @@conf['user']['personal']['columns'].symbolize_values
          end

          def setup!
            @@conf = 
                @@chktable  = @@chkcols   = 
                @@rpltable  = @@rplcols   = 
                @@perstable = @@perscols  = nil
            setup
          end

          def get(params)
            User.setup
            Group.setup

            column      = @@conf['user']['check']['columns']['User-Name'].to_sym
            page        = params[:page].to_i 
            per_page    = params[:per_page].to_i

            q_check     = RADIUS.db[@@chktable].select(
              column      => :username
            )

            q_usergroup = RADIUS.db[Group.maptable].select(
              Group.mapcols['User-Name'] => :username
            )

            union       = (q_check | q_usergroup).group_by :username

            users       = union.paginate(page, per_page).map do |h| 
              h[:username].force_encoding 'utf-8'
            end
            return {
              'total_items' => union.count,
              'page'        => page,
              'per_page'    => per_page,
              'users'       => users.map{|u| new(u)} 
            }
          end
        
        end

        attr_reader :name, :check, :reply, :groups, :personal

        def setup;  self.class.setup;   end
        def setup!; self.class.setup!;  end

        def initialize(username)
          @name     = username
          @check    = []
          @reply    = []
          @groups   = []
          @personal = nil
        end

        def retrieve_attributes_from_db
          setup
          
          @check = RADIUS.db[@@chktable].select(
            @@chkcols.invert
          ).where(
            @@chkcols['User-Name'] => @name
          ).to_a

          @reply = RADIUS.db[@@rpltable].select(
            @@rplcols.invert
          ).where(
            @@rplcols['User-Name'] => @name
          ).to_a
        end

        def retrieve_group_membership_from_db
          User.setup
          Group.setup

          @groups = RADIUS.db[Group.maptable].select(
            Group.mapcols.invert.symbolize_keys
          ).where(
            Group.mapcols['User-Name'] => @name
          ).order_by(
            Group.mapcols['Priority']
          ).to_a
        end

        def retrieve_personal_info_from_db
          setup
          row = RADIUS.db[@@perstable].select(
            @@perscols.invert.symbolize_all
          ).filter(
            @@perscols['User-Name'] => @name
          ).first
          if row
            @personal = row.stringify_keys 
          else 
            @personal = {} 
          end
        end

        def grouplist
          @groups.map{|h| h[:"Group-Name"]}   
        end

        def found?
          @check.any? || @reply.any? || @groups.any? 
        end

        def update_reply_attributes(params)
          setup
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
          validate_empty_password(params)
          if params['check']['Password-Type'] =~ /\S/
            return unless params['check']['User-Password'] =~ /\S/
            # so an incorrect Password-Type would raise an exception
            encrypted_passwd = RADIUS.compute_password(
              :type             => params['check']['Password-Type'],
              :cleartext        => params['check']['User-Password']
            )
          end
          RADIUS.db[@@chktable].filter(
            @@chkcols['User-Name']  => @name
          ).filter(
            @@chkcols['Attribute'].like '%-Password'
          ).delete
          if params['check']['Password-Type'] =~ /\S/
            RADIUS.db[@@chktable].insert(
              @@chkcols['User-Name']  => @name,
              @@chkcols['Attribute']  => params['check']['Password-Type'],
              @@chkcols['Operator']   => ':=',
              @@chkcols['Value']      => encrypted_passwd
            )
          end
        end

        def update_group_membership(params)
          Group.setup
          groupnames = 
              params['groups'].split(/[ ,;\n\r]+/m).reject{|s| s.empty?}  
          groupnames.each{|name| Name.validate name} 
          oldrows = RADIUS.db[Group.maptable].filter(
            Group.mapcols['User-Name'] => @name
          ).to_a
          newrows = []
          groupnames.each_with_index do |groupname, n|
            priority = n + 1
            newrows << {
              Group.mapcols['User-Name']  => @name,
              Group.mapcols['Group-Name'] => groupname,
              Group.mapcols['Priority']   => priority
            }
          end
          delete = oldrows - newrows
          insert = newrows - oldrows
          delete.each{|row| RADIUS.db[Group.maptable].filter(row).delete}
          insert.each do |row| 
            RADIUS.db[Group.maptable].insert(row)
            g = Group.new row[Group.mapcols['Group-Name']] 
            g.retrieve_attributes_from_db
            g.insert_fall_through_if_not_exists
          end 
        end

        def update_personal_data(params)
          setup
          match = {@@perscols['User-Name'] => @name}
          row   = match.clone
          params['personal'].each_pair do |k, v|
            row[@@perscols[k]] = v if @@perscols[k]
          end
          if RADIUS.db[@@perstable].filter(match).any?
            row[@@perscols['Update-Date']] = Time.now
            RADIUS.db[@@perstable].filter(match).update(row) 
          else
            row[@@perscols['Update-Date']] = nil # DaloRADIUS-compatible
            row[@@perscols['Creation-Date']] = Time.now
            RADIUS.db[@@perstable].insert row
          end
        end

        def upload_attachments(params)
          user = params['check']['User-Name'] || params[:userid]
          params['personal']['Attachments'].each do |attachment|
            dir = "#{UPLOADS}/#{user}/personal"
            FileUtils.mkdir_p dir
            FileUtils.cp(
                attachment[:tempfile].path, 
                File.join(dir, attachment[:filename])
            )
          end
        end

        def update(params)
          if params['update_groups']
            update_group_membership(params)
          else
            update_passwd(params)
            update_check_attributes(params)
            update_reply_attributes(params)
            update_personal_data(params)
            upload_attachments(params)
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
            RADIUS::Check.validate_empty_password(params)
          end
        end

        def to_h
          {
            :name     => @name,
            :check    => @check,
            :reply    => @reply,
            :groups   => @groups,
            :personal => @personal,
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

