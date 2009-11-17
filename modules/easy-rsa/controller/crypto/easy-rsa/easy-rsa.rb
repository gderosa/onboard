# OnBoard::Crypto::SSL is part of the core, while OnBoard::Crypto::EasyRSA
# is in a module and is just one of the ways to create/view certs via 
# helper scripts.

require 'sinatra/base'

require 'onboard/crypto/easy-rsa'
require 'onboard/crypto/ssl'

class OnBoard::Controller < Sinatra::Base

  get '/crypto/easy-rsa.:format' do
    # create Diffie-Hellman params if they don't exist
    OnBoard::Crypto::SSL::KEY_SIZES.each do |n|
      Thread.new do
        OnBoard::Crypto::SSL.dh_mutex(n).synchronize do
          unless OnBoard::Crypto::SSL.dh_exists?(n) 
            OnBoard::Crypto::EasyRSA.create_dh(n)
          end
        end
      end
    end
    sleep 0.1 # this is diiiiirty!
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa',
      :format   => params[:format],
      :objects  => OnBoard::Crypto::SSL.getAll() 
    )
  end

  post '/crypto/easy-rsa/ca.:format' do
    if OnBoard::Crypto::EasyRSA::CA.validate_HTTP_POST(params) 
      msg = OnBoard::Crypto::EasyRSA::CA.create_from_HTTP_request(params)
      if msg[:ok]
        status(201)  
      else # client sent a valid request but (server-side) errors occured
        status(500) 
      end     
    else # client sent invalid data
      status(400) 
      msg = {:ok => false, :err => "Invalid data."}
    end
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/ca-create',
      :format   => params[:format],
      :objects  => nil,
      :msg      => msg
    )
  end

=begin  
  put '/network/openvpn.:format' do
    vpns = OnBoard::Network::OpenVPN::VPN.getAll()
    msg = OnBoard::Network::OpenVPN::VPN.modify_from_HTTP_request(params) 
    vpns = OnBoard::Network::OpenVPN::VPN.getAll()
    # Bringin' an OpenVPN connection up is an asynchronous operation,
    # while bringing it down is synchronous.
    if params['start']
      msg[:ok] ? status(202) : status(409) 
    elsif params['stop']
      if not msg[:ok] and msg[:stderr]
        status(409)                       # HTTP 'Conflict'
      else
        status(200)                       # HTTP 'OK'
      end
    end
    format(
      :module   => 'openvpn',
      :path     => '/network/openvpn/vpn',
      :format   => params[:format],
      :objects  => vpns,
      :msg      => msg
    )
  end

  # :vpnid may be an incremental index (@@all_vpn array index +1) 
  # OR
  # a "portable_id" (a more robust way to identify a VPN) 
  #
  # There shouldn't be collisions since the former is a very short integer
  # (though converted to a String) while the latter is a longer string
  # (hex md5 hash).
  #
  delete '/network/openvpn/vpn/:vpn_identifier.:format' do
    vpn = nil
    all = OnBoard::Network::OpenVPN::VPN.getAll()
    # Lookup: first try by portable_id:
    vpn = all.detect {|x| x.data['portable_id'] == params[:vpn_identifier]} 
    # Then try by array index ("old" method)
    unless vpn 
      ary_index = params[:vpn_identifier].to_i - 1
      vpn = OnBoard::Network::OpenVPN::VPN.getAll[ary_index]
    end
    # 
    if vpn 
      vpn.stop()
      OnBoard::Network::OpenVPN::VPN.all_cached.delete vpn
      redirection = "/network/openvpn.#{params[:format]}"
      status(303)                       # HTTP "See Other"
      headers('Location' => redirection)
      # altough the client will move, an entity-body is always returned
      format(
        :path     => '/303',
        :format   => params[:format],
        :objects  => redirection
      )      
    else
      not_found
    end

  end
=end

end
