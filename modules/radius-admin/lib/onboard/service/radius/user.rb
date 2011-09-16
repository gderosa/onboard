require 'date'
require 'fileutils'
require 'facets/hash'
require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/sequel/dataset'
require 'onboard/extensions/object/deep'
require 'onboard/extensions/hash'

# WARNING WARNING WARNING! We're depending upon deprecated features:
# https://github.com/jeremyevans/sequel/pull/373#issuecomment-1816441
#
# TODO: remove the configurable-column-names feature until a robust solution is found

class OnBoard
  module Service
    module RADIUS
      class User

        class InvalidData < BadRequest
=begin # TODO?
          class Name    < BadRequest; end
          class Email   < BadRequest; end
          class Birth   < ...
=end
        end

        UPLOADS = File.join RADIUS::UPLOADS, 'users'

        class << self

          def setup
            # WARNING WARNING WARNING! We're depending upon deprecated features:
            # https://github.com/jeremyevans/sequel/pull/373#issuecomment-1816441
            #
            # TODO: remove the configurable-column-names feature until a robust 
            # solution is found
            #
            # Most of the following hashes are used in various calls to
            # Sequel::Dataset#select 

            @@conf        ||= RADIUS.read_conf
            @@chktable    ||= @@conf['user']['check']['table'].to_sym
            @@chkcols     ||= @@conf['user']['check']['columns'].symbolize_values
            @@rpltable    ||= @@conf['user']['reply']['table'].to_sym
            @@rplcols     ||= @@conf['user']['reply']['columns'].symbolize_values
            @@perstable   ||= @@conf['user']['personal']['table'].to_sym
            @@perscols    ||= 
                @@conf['user']['personal']['columns'].symbolize_values
            @@termstable  ||= @@conf['terms']['table'].to_sym
            @@termsaccepttable ||=
                              @@conf['terms_accept']['table'].to_sym
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

          def by_terms(params)
            User.setup
            Group.setup

            # we do not use sonfigutrable column names here...

            page        = params[:page].to_i 
            per_page    = params[:per_page].to_i

            # use double underscore Sequel notation for tablename.columnname
            q = RADIUS.db[:terms_accept].select(:userinfo__username).filter(:terms_id => params[:terms_id].to_i, :accept => true).join(:userinfo, :terms_accept__userinfo_id => :userinfo__id)
            usernames = q.map(:username)

            return {
              'count' => usernames.length, # q.count would require one more query
              'users' => usernames
            }
          end

          def validate_personal_info(h)
            fields    = h[:fields]
            personal  = h[:params]['personal']
            invalid   = []
            if fields.include? 'Name'
              invalid << 'First Name' unless personal['First-Name'] =~ /\S/
              invalid << 'Last Name'  unless personal['Last-Name']  =~ /\S/
            end
            invalid << 'Email' if fields.include? 'Email' and 
                not personal['Email'] =~ /\S@\S/
            if fields.include? 'Birth' # TODO: granularize: date vs place?
              begin
                Date.parse personal['Birth-Date']
              rescue ArgumentError
                invalid << 'Birth Date'
              end
              invalid << 'Birth City' unless personal['Birth-City'] =~ /\S/
              # TODO? Birth-State?
            end
            if fields.include? 'Full-Address'
              invalid << 'Address'  unless personal['Address']  =~ /\S/
              invalid << 'City'     unless personal['City']     =~ /\S/
              # slightly relaxed: do not demand postcode...
            end
            if fields.include? 'Phone'
              invalid << 'Phone' unless
                  personal['Work-Phone']    =~ /\d/ ||
                  personal['Home-phone']    =~ /\d/ ||
                  personal['Mobile-Phone']  =~ /\d/
            end
            if fields.include? 'ID-Code'
              invalid << 'Tax or Social Security Code' unless personal['ID-Code'] =~ /\S/
            end

            raise InvalidData, "Invalid or missing: #{invalid.join ', '}" if invalid.any?
          end

          def delete_all_attachments
            FileUtils.rm_rf UPLOADS
          end

        end

        attr_reader :name, :check, :reply, :groups, :personal, :accepted_terms

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
        alias retrieve_personal_info retrieve_personal_info_from_db

        # TODO: change :terms_id, :userinfo_id, :id in something configurable
        # but don't use hash aliasing (see above)
        def retrieve_accepted_terms_from_db
          @personal ||= {}
          retrieve_personal_info unless @personal['Id']
          list = RADIUS.db[@@termsaccepttable].select(:terms_id).filter(:userinfo_id => @personal['Id']).map{|h| h[:terms_id]}
          @accepted_terms = Terms::Document.get_all(:id => list) 
        end
        alias retrieve_accepted_terms retrieve_accepted_terms_from_db

        def accept_terms!(accepted_terms)
          setup
          retrieve_personal_info_from_db unless @personal['Id'] 
          raise(
              Conflict, 
              %Q{There's no user named "#{@name}" in userinfo db table}
          ) unless @personal['Id']
          accepted_terms.each do |terms_id|
            # here we use fixed column names!
            RADIUS.db[@@termsaccepttable].insert(
              :userinfo_id  => @personal['Id'],
              :terms_id     => terms_id,
              :accept       => true
            )
          end
        end

        def get_personal_attachment_info
          @personal ||= {}
          dir = "#{UPLOADS}/#{@name}/personal"
          begin
            @personal['Attachments'] = Dir.foreach(dir).select do |entry|
              File.file? "#{dir}/#{entry}"
            end
          rescue Errno::ENOENT
            @personal['Attachments'] = []
          end
        end

        def grouplist
          @groups.map{|h| h[:"Group-Name"]}   
        end

        def found?
          @check.any? || @reply.any? || @groups.any? 
        end

        def update_reply_attributes(params)
          return unless params['reply'].respond_to? :each_pair
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
          return unless  params['check'].respond_to? :each_pair
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
          return unless params['check']
          if params['check']['User-Password'] !=
              params['confirm']['check']['User-Password']
            raise PasswordsDoNotMatch, 'Passwords do not match!'
          end
          validate_empty_password(params)
          unless params['check']['Password-Type'] =~ /\S/
            params['check']['Password-Type'] = password_type
          end
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
          ).delete if params['check']['Password-Type'] # nil != '' ; nil =  unchanged
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
          return unless params['personal'].respond_to? :each_pair
          setup
          match = {@@perscols['User-Name'] => @name}
          row   = match.clone
          params['personal'].each_pair do |k, v|
            row[@@perscols[k]] = v if @@perscols[k]
          end
          begin
            birthdate = Date.parse params['personal']['Birth-Date']
          rescue ArgumentError
            birthdate = Sequel::NULL
          end
          row[@@perscols['Birth-Date']] = birthdate
          if RADIUS.db[@@perstable].filter(match).any?
            row[@@perscols['Update-Date']] = Time.now
            RADIUS.db[@@perstable].filter(match).update(row) 
          else
            row[@@perscols['Update-Date']] = nil # DaloRADIUS-compatible
            row[@@perscols['Creation-Date']] = Time.now
            RADIUS.db[@@perstable].insert row
          end
        end

        def delete_attachments(params)
          if params['delete'].respond_to? :[]
            dir = "#{UPLOADS}/#{@name}/personal"
            params['delete']['personal']['Attachments'].each_pair do |basename, delete|
              FileUtils.rm "#{dir}/#{basename}" if delete == 'on'
            end
          end
        end

        def upload_attachments(params)
          # user = params['check']['User-Name'] || params[:userid]
          if params['personal'] and params['personal']['Attachments'].respond_to? :each
            params['personal']['Attachments'].each do |attachment|
              dir = "#{UPLOADS}/#{@name}/personal"
              FileUtils.mkdir_p dir
              FileUtils.cp(
                  attachment[:tempfile].path, 
                  File.join(dir, attachment[:filename])
              )
            end
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
            delete_attachments(params)
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

        def stored_password
          find_attribute_value_by_name :check, password_type
        end

        def check_password(cleartext) 
          begin
            passwd = Passwd.new :type => password_type, :cleartext => cleartext
            return passwd.check stored_password
          rescue Passwd::UnknownType
            return false
          end
        end

        def validate_empty_password(params)
          # if password type is not being changed, leaving the password
          # fields blank simply means "leave the password unchanged".
          if password_type != params['check']['Password-Type']
            RADIUS::Check.validate_empty_password(params)
          end
        end


        def auth_type
          find_attribute_value_by_name(:check, 'Auth-Type')
        end

        def to_h
          {
            :name           => @name,
            :check          => @check,
            :reply          => @reply,
            :groups         => @groups,
            :personal       => @personal,
            :accepted_terms => @accepted_terms
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

