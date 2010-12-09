require 'sequel'
require 'sequel/extensions/pagination'

require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      class User

        class << self

          def get(params)
            conf      = RADIUS.read_conf
            table     = conf['check']['table'].to_sym
            column    = conf['check']['columns']['User-Name'].to_sym
            page      = params[:page].to_i 
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[table].select(column).group_by(column)
            users     = select.paginate(page, per_page).map{|h| h[column]} 

            {
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page,
              'users'       => users.map{|u| new(u)} 
            }
          end
        
        end

        attr_reader :name

        def initialize(username)
          @name = username
        end

        def to_h
          {
            'name' => @name
          }
        end

        def to_json(*args); to_h.to_json(*args); end
        def to_yaml(*args); to_h.to_yaml(*args); end

      end
    end
  end
end

