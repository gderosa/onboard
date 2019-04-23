require 'date'
require 'fileutils'
require 'facets/hash'
require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/sequel'
require 'onboard/extensions/object/deep'
require 'onboard/extensions/hash'

# NOTE: According to
# https://github.com/jeremyevans/sequel/pull/373#issuecomment-1816441
# we're trying to adopt correct syntax (with Sequel.as or :mycolumn___myalias)

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
              Sequel.as(column, :username)#, Sequel.as(:id, :my_aliased_id)
            )

            q_usergroup = RADIUS.db[Group.maptable].select(
              Sequel.as(Group.mapcols['User-Name'], :username)
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

          # Currently just
          #   find :Email => 'email@address' # uppercase key to mimic attributes...
          def find(h)
            # TODO: DRY
            User.setup
            Group.setup

            if h[:Email]
              email = h[:Email]

              row = RADIUS.db[@@perstable].select(
                *Sequel.aliases(@@perscols.invert)
              ).filter(
                @@perscols['Email'] => email
              ).first
              if row
                personal = row.stringify_keys
                user = User.new personal['User-Name']
                user.personal = personal

                user.retrieve_attributes_from_db
                user.retrieve_group_membership_from_db
                # retrieve_personal_info_from_db # unnecessary, already done
                user.retrieve_accepted_terms_from_db

                return user
              else
                return nil
              end
            end
          end

          def by_terms(params)
            User.setup
            Group.setup

            # we do not use configurable column names here...

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

          def params_key_to_i18n(key, i18n)
            h = {
              'Email' => 'e-mail'
            }
            if i18n
              h.update( {
                'First-Name'  => i18n.personal.name.first,
                'Last-Name'   => i18n.personal.name.last,
                'Birth-Date'  => i18n.personal.birth.date,
                'Birth-City'  => i18n.personal.birth.place,
                'Address'     => i18n.personal.address,
                'City'        => i18n.personal.city,
                'Phone'       => i18n.personal.phone.phone,
                'ID-Code'     => i18n.personal.id_code.id_code,
              } )
              return h[key].capitalize
            else
              return key.split('-').map{|s| s.capitalize}.join(' ')
            end
          end

          def validate_personal_info(h)
            fields    = h[:fields]
            personal  = h[:params]['personal']
            i18n      = h[:i18n]
            # pp i18n # DEBUG
            invalid   = []
            if fields.include? 'Name'
              %w{First-Name Last-Name}.each do |k|
                invalid << params_key_to_i18n(k, i18n) unless personal[k] =~ /\S/
              end
            end
            invalid << 'Email' if fields.include? 'Email' and 
                not personal['Email'] =~ /\S@\S/
            if fields.include? 'Birth' # TODO: granularize: date vs place?
              begin
                Date.parse personal['Birth-Date']
              rescue ArgumentError
                invalid << params_key_to_i18n('Birth-Date', i18n)
              end
              invalid <<  params_key_to_i18n('Birth-City', i18n) unless personal['Birth-City'] =~ /\S/
              # TODO? Birth-State?
            end
            if fields.include? 'Full-Address'
              %w{Address City}.each do |k|
                invalid << params_key_to_i18n(k, i18n) unless personal[k]  =~ /\S/
              end
              # slightly relaxed: do not demand postcode...
            end
            if fields.include? 'Phone'
              invalid <<  params_key_to_i18n('Phone', i18n) unless
                  personal['Work-Phone']    =~ /\d/ ||
                  personal['Home-phone']    =~ /\d/ ||
                  personal['Mobile-Phone']  =~ /\d/
            end
            if fields.include? 'ID-Code'
              invalid << params_key_to_i18n('ID-Code', i18n) unless personal['ID-Code'] =~ /\S/
            end

            # raise InvalidData, "Invalid or missing: #{invalid.join ', '}" if invalid.any?
            raise \
              InvalidData,\
              "#{i18n.invalid_or_missing_info(invalid.size).capitalize}: #{invalid.join ', '}" if invalid.any?
          end

          def delete_all_attachments
            FileUtils.rm_rf UPLOADS
          end

        end

        attr_reader :name, :check, :reply, :groups, :personal, :accepted_terms
        attr_writer :personal

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
            *Sequel.aliases(@@chkcols.invert)
          ).where(
            @@chkcols['User-Name'] => @name
          ).to_a

          @reply = RADIUS.db[@@rpltable].select(
            *Sequel.aliases(@@rplcols.invert)
          ).where(
            @@rplcols['User-Name'] => @name
          ).to_a
        end

        def retrieve_group_membership_from_db
          User.setup
          Group.setup

          @groups = RADIUS.db[Group.maptable].select(
            *Sequel.aliases(Group.mapcols.invert)
          ).where(
            Group.mapcols['User-Name'] => @name
          ).order_by(
            Group.mapcols['Priority']
          ).to_a
        end

        def retrieve_personal_info_from_db
          setup

          row = RADIUS.db[@@perstable].select(
            *Sequel.aliases(@@perscols.invert)
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

        def retrieve_info_from_db
          retrieve_attributes_from_db
          retrieve_group_membership_from_db
          retrieve_personal_info_from_db
          retrieve_accepted_terms_from_db
        end

        def delete!
          setup

	        # Because of referential integrity, accepted terms rows must be deleted first.

	        # Terms & Conditions doesnt't have configurable column names...
          RADIUS.db[@@termsaccepttable].where(:userinfo_id             => @personal['Id']).delete

          RADIUS.db[@@chktable        ].where(@@chkcols[  'User-Name'] => @name          ).delete
          RADIUS.db[@@rpltable        ].where(@@rplcols[  'User-Name'] => @name          ).delete
          RADIUS.db[@@perstable       ].where(@@perscols[ 'User-Name'] => @name          ).delete
          update_group_membership 'groups' => ''
        end

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
            # passwords are managed by #update_passwd
            next if attribute =~ /-Password$/ or attribute =~ /^Password-/
            # inserting User-Name attribute doesn't make sense: there's
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
          # params['check']['Password-Type']:
          # nil:  leave unchanged
          # '' :  no password - e.g. group authentication
          unless params['check']['Password-Type']
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
            Sequel.like(@@chkcols['Attribute'], '%-Password')
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

        def update_password_direct(password)
          # fake an "html form"
          params = {
            'check'   => {
              'User-Password' => password
            },
            'confirm' => {
              'check'   => {
                'User-Password' => password
              }
            }
          }
          update_passwd params
        end

        def update_group_membership(params)
          Group.setup
          if params['groups'].respond_to? :split
              groupnames =
                params['groups'].split(/[ ,;\n\r]+/m).reject{|s| s.empty?}
          else  # Array...
              groupnames = params['groups']
          end
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
            # g.insert_fall_through_if_not_exists
          end
          insert_fall_through_if_not_exists if groupnames.any?
        end

        def insert_fall_through_if_not_exists
          setup
          unless @reply.find do |row|
            row[:Attribute] == 'Fall-Through' and
            row[:Operator]  =~ /=$/           and
            row[:Value]     =~ /yes/i
          end
            LOGGER.info "radius-admin: I am inserting Fall-Through reply attribute for user #{@name}!"
            RADIUS.db[@@rpltable].insert(
              @@rplcols['User-Name']  => @name,
              @@rplcols['Operator']   => '=',
              @@rplcols['Attribute']  => 'Fall-Through',
              @@rplcols['Value']      => 'yes'
            )
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
          rescue ArgumentError, TypeError
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

        #   user.find_attribute(:check) do |attr, op, val|
        #     attr =~ /-Password$/
        #   end
        #
        #   user.find_attribute(:check) do |attr, op, val|
        #     attr == 'Auth-Type'
        #   end
        #
        #   user.find_attribute(:reply) do |attr, op, val|
        #     attr == 'Idle-Timeout' and val < 1800
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

