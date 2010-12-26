class OnBoard
  module Service
    module RADIUS
      module Db
        class << self
          def reset_data(params)
            tables = []
            if params['resetdata']
              if params['resetdata']['default'] =~ /on|yes|true/
                tables += [
                  RADIUS.conf['user']['personal']['table'],
                  RADIUS.conf['user']['check']['table'],
                  RADIUS.conf['user']['reply']['table'],
                  RADIUS.conf['group']['check']['table'],
                  RADIUS.conf['group']['reply']['table'],
                  RADIUS.conf['group']['usermap']['table']
                ]
              end
              if params['resetdata']['accounting'] =~ /on|yes|true/
                tables += [
                  RADIUS.conf['accounting']['table'] 
                ]
              end
            end
            tables.each do |table|
              RADIUS.db[table.to_sym].delete 
            end
            tables
          end
        end
      end
    end
  end
end
