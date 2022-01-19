require 'sinatra/base'

require 'onboard/network/iptables'

class OnBoard::Controller

  get '/network/packet-mangling:format' do
    redirect '/network/packet-mangling/ipv4.' + params[:format], 10
  end

  get '/network/packet-mangling/ipv:version.:format' do
    not_found unless %w{4 6}.include? params[:version]

    iptablesobj = OnBoard::Network::Iptables.new(
      :ip_version => params[:version],
      :tables => %w{mangle}
    )
    iptablesobj.get_all_info

    format(
      :path => '/network/packet-mangling',
      :format => params[:format],
      :objects  => iptablesobj,
      :title  => "Packet Mangling (IPv#{params[:version]})"
    )
  end

  # Again, we UPDATE one big resource (the whole mangle table), instead of
  # CREATEing or DELETEing single rules...
  put '/network/packet-mangling/ipv:version.:format' do
    not_found unless %w{4 6}.include? params[:version]

    params['table'] = 'mangle'

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
      :tables => %w{mangle}
    )
    iptablesobj.get_all_info

    format(
      :path => '/network/packet-mangling',
      :format => params[:format],
      :objects  => iptablesobj,
      :msg  => msg,
      :title  => "Packet Mangling (IPv#{params[:version]})"
    )
  end

end
