require 'sinatra/base'

require 'onboard/network/iptables'

# TODO TODO TODO: DRY! DRY! DRY!

class OnBoard::Controller

  get '/network/firewall.:format' do
    redirect '/network/firewall/ipv4.' + params[:format], 10
  end

  get '/network/firewall/ipv:version.:format' do
    not_found unless %w{4 6}.include? params[:version]

    iptablesobj = OnBoard::Network::Iptables.new(
      :ip_version => params[:version],
      :tables => %w{filter}
    )
    iptablesobj.get_all_info

    format(
      :path     => '/network/firewall',
      :format   => params[:format],
      :objects  => iptablesobj,
      :title    => "Firewall (IPv#{params[:version]})"
    )
  end

  # Again, we UPDATE one big resource (the whole firewall), instead of
  # CREATEing or DELETEing single rules...
  put '/network/firewall/ipv:version.:format' do
    not_found unless %w{4 6}.include? params[:version]

    msg = OnBoard::Network::Iptables.add_rule_from_HTTP_request(params) if
      params['add_rule']
    msg = OnBoard::Network::Iptables.del_rule_from_HTTP_request(params) if
      params['del_rule']
    msg = OnBoard::Network::Iptables.move_rule_up_from_HTTP_request(params) if
      params['move_rule_up']
    msg = OnBoard::Network::Iptables.move_rule_down_from_HTTP_request(params) if
      params['move_rule_down']
    if msg.respond_to? :[]
      # taken from routing.rb
      unless msg[:ok] # TODO: always sure the error is client-side?
        status(409)   # TODO: what is the most appropriate HTTP response in this
                      # case? 400 Bad Request? 409 Conflict?
        #headers("X-STDERR" => msg[:stderr].strip.gsub("\n","\\n"))
      end
    end

    iptablesobj = OnBoard::Network::Iptables.new(
      :ip_version => params[:version],
      :tables => %w{filter}
    )
    iptablesobj.get_all_info

    format(
      :path     => '/network/firewall',
      :format   => params[:format],
      :objects  => iptablesobj,
      :msg      => msg,
      :title    => "Firewall (IPv#{params[:version]})"
    )
  end

end
