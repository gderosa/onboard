require 'sequel'

require 'onboard/controller/error'
require 'onboard/service/radius/db'

class OnBoard
  class Controller < Sinatra::Base

    on_error Sequel::DatabaseConnectionError do |e, request|
      if request.path_info =~ %r{^/services/radius/}
        {
          :status => 500,
          :msg    => {:err => Service::RADIUS::Db.format_error_msg(e)} 
        }
      end #=> else nil
    end

  end
end
