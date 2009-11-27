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

  get '/crypto/easy-rsa/ca/index.txt' do
    index_txt = OnBoard::Crypto::EasyRSA::KEYDIR + '/index.txt'
    if File.exists? index_txt
      content_type 'text/plain'
      attachment "index.txt"
      File.read index_txt
    else
      not_found
    end
  end

  post '/crypto/easy-rsa/ca.:format' do
    msg = {}
    if msg[:err] = OnBoard::Crypto::EasyRSA::CA.HTTP_POST_data_invalid?(params) 
      # client sent invalid data
      status(400)
    else
      msg = OnBoard::Crypto::EasyRSA::CA.create_from_HTTP_request(params)
      if msg[:ok]
        status(201)  
      else # client sent a valid request but (server-side) errors occured
        status(500) 
      end     
    end
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/ca-create',
      :format   => params[:format],
      :objects  => nil,
      :msg      => msg
    )
  end

  post '/crypto/easy-rsa/certs.:format' do
    msg = {}
    if msg[:err] = 
        OnBoard::Crypto::EasyRSA::Cert.HTTP_POST_data_invalid?(params) 
      # client sent invalid data
      status(400)
    else
      msg = OnBoard::Crypto::EasyRSA::Cert.create_from_HTTP_request(params)
      if msg[:ok]
        status(201)  
      else # client sent a valid request but (server-side) errors occured
        status(500) 
      end     
    end
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/cert-create',
      :format   => params[:format],
      :objects  => nil,
      :msg      => msg
    )
  end

  # A WebService client does not need an entity-body (headers and Status
  # will suffice), so html is fine as well, since it will be ignored...
  delete '/crypto/easy-rsa/certs/:name.crt' do
    msg = {}
    certfile = "#{OnBoard::Crypto::SSL::CERTDIR}/#{params[:name]}.crt"
    keyfile = "#{OnBoard::Crypto::SSL::CERTDIR}/private/#{params[:name]}.key"
    if File.exists? certfile
      begin
        msg = OnBoard::System::Command.run <<EOF
cd #{OnBoard::Crypto::EasyRSA::SCRIPTDIR}
. ./vars
./revoke-full #{params['name']}
EOF
        FileUtils.rm certfile
        FileUtils.rm keyfile if File.exists? keyfile
      rescue
        msg = {:ok=> false, :err => $!}
        status(500)
      end
      format(
        :path => '/crypto/ssl/cert_del',
        :format => 'html',
        :objects => {},
        :msg => msg
      )
    else
      not_found
    end
  end

 
end
