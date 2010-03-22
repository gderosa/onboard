require 'sinatra/base'

require 'onboard/extensions/openssl'

class OnBoard

  module Crypto
    autoload :SSL, 'onboard/crypto/ssl'
  end

  module System
    autoload :Log, 'onboard/system/log'
  end

  module Network
    module OpenVPN
      autoload :VPN, 'onboard/network/openvpn/vpn'
    end
  end

  class Controller < Sinatra::Base

    get '/network/openvpn.:format' do
      vpns = OnBoard::Network::OpenVPN::VPN.getAll()
      format(
        :module => 'openvpn',
        :path => '/network/openvpn/vpn',
        :format => params[:format],
        :objects  => vpns
      )
    end

    post '/network/openvpn.:format' do
      msg = {:ok => true}
      vpns = OnBoard::Network::OpenVPN::VPN.getAll()
      certfile = "#{Crypto::SSL::CERTDIR}/#{params['cert']}.crt"

      begin
        certobj = OpenSSL::X509::Certificate.new(File.read certfile) 
        requested_cn = certobj.to_h['subject']['CN']
        # The following check should be done by openvpn, which should exit
        # with a non-zero status... unfortunately it isn't, and you end with
        # two tun interface with same IP addresses! So, a validation is necessary.
        vpns.each do |vpn|
          if
              vpn.data['remote'].respond_to? :[]      and

              params['remote_host']                   and

              vpn.data['remote']['address'].strip == 
                  params['remote_host'].strip         and
                    # TODO: use gethostbyname when useful?
                    # NOTE: the two values compared may be IP addresses as well
                    # as DNS host names.       
              vpn.data['remote']['port'].strip    == 
                  params['remote_port'].strip         and

              vpn.data['cert']['subject']['CN']   == 
                  requested_cn
            msg = {
                :ok => false,
                :err => 'A client VPN connection to the same server/port and with the same SSL "Common Name" is already running!'
            }
            break
          end
        end
      rescue OpenSSL::X509::CertificateError
        msg = {
            :ok => false, 
            :err => "#{$!.class.name}: #{$!.to_s}", 
            :err_html => "OpenSSL Certificate error: &ldquo;<code>#{html_escape $!.to_s}</code>&rdquo;"
        }
      rescue Errno::ENOENT
        msg = {
          :ok => false,
          :err => "No Certificate file!",
          :status_http => 400 # Bad Request
        }
      end
      if msg[:ok]
        msg = OnBoard::Network::OpenVPN::VPN.start_from_HTTP_request(params)
      end
      if msg[:ok]
        vpns = OnBoard::Network::OpenVPN::VPN.getAll()
        status(201) # HTTP Created
      elsif msg[:status_http]
        status msg[:status_http]
      else
        status(409) # HTTP Conflict by default
      end
      format(
        :module => 'openvpn',
        :path => '/network/openvpn/vpn',
        :format => params[:format],
        :objects  => vpns,
        :msg  => msg
      )
    end

    put '/network/openvpn.:format' do
      vpns = OnBoard::Network::OpenVPN::VPN.getAll()
      msg = OnBoard::Network::OpenVPN::VPN.modify_from_HTTP_request(params) 
      sleep 0.3 # diiiirty!
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
    # a "portable_id" (a md5 hash of command line etc..) 
    # OR
    # 'uuid'.
    #
    # There shouldn't be collisions because of different formats.
    #
    # TODO: get rid of 'portable_id' / switch to uuid?
    #
    get '/network/openvpn/vpn/:vpn_identifier.:format' do
      vpn = OnBoard::Network::OpenVPN::VPN.lookup(
        :any => params[:vpn_identifier]
      ) 
      if vpn 
        format(
          :module   => 'openvpn',
          :path     => '/network/openvpn/vpn/advanced',
          :format   => params[:format],
          :objects  => vpn
        )      
      else
        not_found
      end
    end

    delete '/network/openvpn/vpn/:vpn_identifier.:format' do
      vpn = OnBoard::Network::OpenVPN::VPN.lookup(
        :any => params[:vpn_identifier]
      ) 
      if vpn 
        vpn.stop(:rmlog, :rmconf) 
        OnBoard::Network::OpenVPN::VPN.all_cached.delete vpn
        sleep 0.3 # diiirty!
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

  end

end
