require 'pp'
require 'sinatra/base'

require 'onboard/network/interface'

class OnBoard::Controller

  get '/network/interfaces.:format' do
    format(
      :path => '/network/interfaces',
      :format => params[:format],
      :objects  => OnBoard::Network::Interface.getAll
    )
  end

  # An example params is found in doc/  
  put '/network/interfaces.:format' do
    current_interfaces = OnBoard::Network::Interface.getAll
    params['netifs'].each_pair do |ifname, ifhash|
      interface = current_interfaces.detect {|i| i.name == ifname}
      interface.modify_from_HTTP_request(ifhash) 
    end
    status(202)                       # HTTP "Accepted"
    headers(
      "Location"      => request.path_info,
      "Pragma"        => "no-cache",  # HTTP/1.0
      "Cache-Control" => "no-cache"   # HTTP/1.1
    ) 
    format(
      :path => '/network/interfaces',
      :format => params[:format],
      :objects  => OnBoard::Network::Interface.getAll
    ) 
  end

end
