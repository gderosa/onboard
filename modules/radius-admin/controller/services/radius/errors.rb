require 'sequel'

require 'onboard/controller/error'
require 'onboard/service/radius/db'

class OnBoard
  class Controller < Sinatra::Base
    on_error Sequel::DatabaseError do |e, request|
      if request.path_info =~ %r{^/services/radius/}
        # TODO?: parse exception message?  
        status, check_your_db_config = 500, true # just for scoping 
        case e 
        when Sequel::DatabaseConnectionError # db misconfigured
          status, check_your_db_config = 500, true  # HTTP Internal Server Error
        when Sequel::DatabaseError # foreign key etc.
          status, check_your_db_config = 409, false # HTTP Conflict
        end                  
        {
          :status => status,
          :msg    => {
            :err => Service::RADIUS::Db.format_error_msg(e, :check_your_config_msg => check_your_db_config)
          } 
        }
      end #=> else nil
    end
  end
end
