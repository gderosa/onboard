require 'sinatra/base'

require 'onboard/network/routing'

class OnBoard::Controller

  get "/network/routing/tables.:format" do
    format(
      :path     => 'network/routing/tables',
      :format   => params[:format],
      :objects  => OnBoard::Network::Routing::Table.getAllIDs
    )
  end

  post "/network/routing/tables.:format" do
    msg = {}
    all = OnBoard::Network::Routing::Table.getAllIDs
    already_used_numbers = all['system_tables'].keys + all['custom_tables'].keys
    params['number'].strip!
    params['name'] = params['name'].strip.gsub(/\s/, '_')
    if params['number'] =~ /^\d+$/
      n = params['number'].to_i
      if (1..255).include? n
        if already_used_numbers.include? n 
          status 409 # Conflict
          msg = {:err => "Error: table number #{n} already in use."}
        else
          OnBoard::Network::Routing::Table.create_from_HTTP_request(params)
        end
      else
        status 400 # Bad Request
        msg = {:err => "Invalid table number: allowed range: 1-255"} 
      end
    else
      status 400 # Bad Request
      msg = {:err => "Invalid table number: \"#{params['number']}\""}
    end

    format(
      :path     => 'network/routing/tables',
      :format   => params[:format],
      :objects  => OnBoard::Network::Routing::Table.getAllIDs,
      :msg      => msg
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
    if params['name']
      msg = OnBoard::Network::Routing::Table.rename(
        table.number, params['name'], params['comment']
      )
      redirect "/network/routing/tables/#{params['name']}.#{params['format']}"
    elsif params['ip_route_del']
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
