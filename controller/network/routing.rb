require 'sinatra/base'

require 'onboard/network/routing'
require 'onboard/network/routing/table'

class OnBoard::Controller

  get "/network/routing/tables.:format" do
    format(
      :path     => 'network/routing/tables',
      :format   => params[:format],
      :title    => 'Policy routing: tables',
      :objects  => OnBoard::Network::Routing::Table.getAllIDs
    )
  end

  post "/network/routing/tables.:format" do
    msg = {}
    all = OnBoard::Network::Routing::Table.getAllIDs
    already_used_numbers  = all['system_tables'].keys + all['custom_tables'].keys
    already_used_names    = (
      all['system_tables'].values + 
      all['custom_tables'].values
    )
    params['number'].strip!
    params['name'] = params['name'].strip.gsub(/\s/, '_')
    if already_used_names.include? params['name']
      status 409 # Conflict
      msg = {:err => "Error: table name \"#{params['name']}\" already in use."}
    elsif params['number'] =~ /^\d+$/
      n = params['number'].to_i
      if (1..255).include? n
        if already_used_numbers.include? n 
          status 409 # Conflict
          msg = {:err => "Error: table number #{n} already in use."}
        elsif params['name'] =~ OnBoard::Network::Routing::Table::VALID_NAMES
          OnBoard::Network::Routing::Table.create_from_HTTP_request(params)
        else
          status 400
          msg = {:err => "Invalid name: \"#{params['name']}\". Use at least one alphabetical character; you may also use numbers, '-' and '_'."}
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
      :title    => 'Policy routing: tables',
      :objects  => OnBoard::Network::Routing::Table.getAllIDs,
      :msg      => msg
    )
  end

  get "/network/routing/rules.:format" do
    format(
      :path     => 'network/routing/rules',
      :format   => params[:format],
      :title    => 'Policy routing: rules',
      :objects  => OnBoard::Network::Routing::Rule.getAll
    )
  end

  post "/network/routing/rules.:format" do
    msg = OnBoard::Network::Routing::Rule.add_from_HTTP_request(params)
    format(
      :path     => 'network/routing/rules',
      :format   => params[:format],
      :title    => 'Policy routing: rules',
      :objects  => OnBoard::Network::Routing::Rule.getAll,
      :msg      => msg
    )
  end
 
  put "/network/routing/rules.:format" do
    msg = OnBoard::Network::Routing::Rule.change_from_HTTP_request(
      :http_params    => params,
      :current_rules  => OnBoard::Network::Routing::Rule.getAll
    )
    format(
      :path     => 'network/routing/rules',
      :format   => params[:format],
      :title    => 'Policy routing: rules',
      :objects  => OnBoard::Network::Routing::Rule.getAll,
      :msg      => msg
    )
  end
 
  get "/network/routing/tables/:table.:format" do
    begin
      format(
        :path     => 'network/routing/table',
        :format   => params[:format],
        :title    => "Routing table: #{params[:table]}",
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
    format = params[:format]
    number = table.number
    all = OnBoard::Network::Routing::Table.getAllIDs
    names = (
      all['system_tables'].values + 
      all['custom_tables'].values
    ).select{|n| n =~ /\S/}
    comment = params['comment'].strip if params['comment']
    if params['name']
      name = params['name'].strip.gsub(' ', '_') 
      #
      # One may just want to change the comment...
      #
      #if names.include? name 
      #  status 409 # HTTP Conflict!
      #  msg = {:err => "Name \"#{name}\" already in use!"}
      #elsif
      if name =~ OnBoard::Network::Routing::Table::VALID_NAMES
        msg = OnBoard::Network::Routing::Table.rename number, name, comment
        if name == ''
            redirect "/network/routing/tables/#{number}.#{format}"      
        else
          redirect "/network/routing/tables/#{name}.#{format}"
        end
      else
        status 400 # Bad Request
        msg = {:err => "Invalid name: \"#{name}\". Use at least one alphabetical character; you may also use numbers, '-' and '_'."}
      end
    elsif params['ip_route_del']
      # 'default' might be ambiguous, 0.0.0.0/0 or ::/0 ? So, specifying
      # the address family (af) is required.
      msg = table.ip_route_del params['ip_route_del'], :af => params['af']
    else
      pp params  # DEBUG
      msg = OnBoard::Network::Routing::Table.route_from_HTTP_request params
    end
    unless msg[:ok] # TODO: always sure the error is client-side?
      status(400)   # TODO: what is the most appropriate HTTP response in this
                    # case? 400 Bad Request? 409 Conflict?
      #headers("X-STDERR" => msg[:stderr].strip.gsub("\n","\\n")) 
    end
    format(
      :path     => 'network/routing/table',
      :format   => params[:format],
      :title    => "Routing table: #{params[:table]}",
      :objects  => OnBoard::Network::Routing::Table.get(params['table']),
      :msg      => msg
    )   
  end

  delete "/network/routing/tables/:table.:format" do
    msg = {}
    table = OnBoard::Network::Routing::Table.get(params['table'])
    if table.system?
      msg[:err]  = "You cannot delete a system table!"
      status 403 # Forbidden
    else
      begin
        msg = table.delete!
      rescue OnBoard::Network::Routing::RulesExist
        msg = {
          :err => $!.to_s,
          :err_html => 'Couldn&apos;t delete: one or more <a href="/network/routing/rules.html">rules</a> still refer to this table! <a href="/network/routing/rules.html">Delete them</a> and try again.'
        }
        status 409 # HTTP Conflict
      end
    end
    if msg[:ok]
      redirect "/network/routing/tables.#{params[:format]}" 
    else
      format(
        :path     => 'network/routing/table',
        :format   => params[:format],
        :title    => "Routing table: #{params['table']}",
        :objects  => OnBoard::Network::Routing::Table.get(params['table']),
        :msg      => msg
      )   
    end
  end

end
