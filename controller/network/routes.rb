require 'sinatra/base'

require 'onboard/network/routing'

class OnBoard::Controller

=begin  
  ["/network/routes.:format", "/network/routing.:format"].each do |r|
    get r do
      redirect "/network/routing/tables/main.#{params['format']}"
    end
  end
=end

  get "/network/routing/tables.:format" do
    format(
      :path     => 'network/routing/tables',
      :format   => params[:format],
      :objects  => OnBoard::Network::Routing::Table.getAllIDs
    )
  end

  get "/network/routing/rules.:format" do
    format(
      :path     => 'network/routing/rules',
      :format   => params[:format],
      :objects  => OnBoard::Network::Routing::Rule.getAll
    )
  end

  get "/network/routing/tables/:table.:format" do
    begin
      format(
        :path     => 'network/routing/table',
        :format   => params[:format],
        :objects  => OnBoard::Network::Routing::Table.get(params[:table])
      )
    rescue OnBoard::Network::Routing::Table::NotFound
      raise Sinatra::NotFound
    end
  end

  # Instead of CREATEing or DELETEing ip routes, we UPDATE the ip routing 
  # table, hence the use of the sole PUT method to an unique URI. 
  # A way to retain our code simple but still respect (somewhat) 
  # the HTTP semantics.
  put "/network/routing/tables/:table.:format" do
    table = OnBoard::Network::Routing::Table.get(params[:table]) 
    if params['ip_route_del']
      msg = table.ip_route_del params['ip_route_del']
    else
      msg = OnBoard::Network::Routing::Table.route_from_HTTP_request params
    end
    unless msg[:ok] # TODO: always sure the error is client-side?
      status(409)   # TODO: what is the most appropriate HTTP response in this
                    # case? 400 Bad Request? 409 Conflict?
      #headers("X-STDERR" => msg[:stderr].strip.gsub("\n","\\n")) 
    end
    format(
      :path     => 'network/routing/table',
      :format   => params[:format],
      :objects  => OnBoard::Network::Routing::Table.get(params['table']),
      :msg      => msg
    )   
  end

end
