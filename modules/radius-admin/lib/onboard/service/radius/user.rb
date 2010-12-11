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
              h[column]
            end

            {
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page,
              'users'       => users.map{|u| new(u)} 
            }
          end
        
        end

        attr_reader :name

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
          @reply = RADIUS.db[@@chktable].where(
            @@chkcols['User-Name'] => @name
          ).to_a
        end

        def to_h
          {
            :name  => @name,
            :check => @check,
            :reply => @reply,
          }
        end

        def to_json(*args)
          to_h.deep_rekey{|k|k.to_s}.to_json(*args)
        end
        def to_yaml(*args)
          to_h.deep_rekey{|k|k.to_s}.to_yaml(*args)
        end

      end
    end
  end
end

