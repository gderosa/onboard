require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/object/deep'
require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      class User

        class << self

          def setup
            @@conf      ||= RADIUS.read_conf
            @@chktable  ||= @@conf['check']['table'].to_sym
            @@chkcols   ||= @@conf['check']['columns'].symbolize_values
            @@rpltable  ||= @@conf['reply']['table'].to_sym
            @@rplcols   ||= @@conf['reply']['columns'].symbolize_values
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
            RADIUS.db[@@rpltable].insert(
              @@rplcols['User-Name']  => @name,
              @@rplcols['Attribute']  => attribute,
              @@rplcols['Operator']   => ':=',
              @@rplcols['Value']      => value
            )
          end
        end

        def update(params)
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

