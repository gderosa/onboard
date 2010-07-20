# OnBoard::Crypto::SSL is part of the core, while OnBoard::Crypto::EasyRSA
# is in a module and is just one of the ways to create/view certs via 
# helper scripts.

require 'sinatra/base'

require 'onboard/system/command'
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
      :objects  => OnBoard::Crypto::SSL.getAll(),
      :title    => 'SSL keys and certificates'
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

  get '/crypto/easy-rsa/ca/crl.:sslformat' do
    # CRL is stored in PEM format
    crl_pem = OnBoard::Crypto::EasyRSA::KEYDIR + '/crl.pem'
    if File.exists? crl_pem
      case params[:sslformat]
      when 'pem'
        content_type 'application/pkix-crl'
        attachment "crl.pem"
        crl = OpenSSL::X509::CRL.new File.read crl_pem
        crl.to_text + crl.to_s
      when 'der'
        content_type 'application/x-x509-crl'
        attachment "crl.der"
        OpenSSL::X509::CRL.new(File.read(crl_pem)).to_der
      else
        not_found # Multiple Choices appropriately
      end
    else
      not_found # TODO: more exception handling
    end
  end

  delete '/crypto/easy-rsa/ca.:format' do
    msg = OnBoard::System::Command.run <<EOF
cd #{OnBoard::Crypto::EasyRSA::SCRIPTDIR}    
export KEY_DIR=#{OnBoard::Crypto::EasyRSA::KEYDIR}
./clean-all    
EOF
    FileUtils.rm OnBoard::Crypto::SSL::CACERT
    FileUtils.rm OnBoard::Crypto::SSL::CAKEY

    redirection = "/crypto/easy-rsa.#{params['format']}"      
    status(303)                       # HTTP "See Other"
    headers('Location' => redirection)
    format(
      :path     => '/303',
      :format   => params['format'],
      :title    => 'SSL keys and certificates'
    )
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
      :msg      => msg,
      :title    => 'SSL keys and certificates'
    )
  end

  # cert. creation and signature by our CA
  post '/crypto/easy-rsa/certs.:format' do
    msg = {}
    if msg[:err] = 
        OnBoard::Crypto::EasyRSA::Cert.HTTP_POST_data_invalid?(params) 
      # client sent invalid data
      #
      status(400)
    else
      msg = OnBoard::Crypto::EasyRSA::Cert.create_from_HTTP_request(params)
      if msg[:ok]
        status(201)  
      elsif msg[:err] =~ /already exists/
        status(409) # Conflict
      else # client sent a valid request but (server-side) errors occured
        status(500) 
      end     
    end
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/cert-create',
      :format   => params[:format],
      :objects  => nil,
      :msg      => msg,
      :title    => 'SSL keys and certificates'
    )
  end

  # A WebService client does not need an entity-body (headers and Status
  # will suffice), so html is fine as well, since it will be ignored...
  delete '/crypto/easy-rsa/certs/:name.crt' do
    msg = {:ok => true} 
    certfile = "#{OnBoard::Crypto::SSL::CERTDIR}/#{params[:name]}.crt"
    keyfile = "#{OnBoard::Crypto::SSL::CERTDIR}/private/#{params[:name]}.key"
    certfile_easyrsa = 
        "#{OnBoard::Crypto::EasyRSA::KEYDIR}/#{params[:name]}.crt"
    keyfile_easyrsa = 
      "#{OnBoard::Crypto::EasyRSA::KEYDIR}/#{params[:name]}.key"
    csr_easyrsa = 
      "#{OnBoard::Crypto::EasyRSA::KEYDIR}/#{params[:name]}.csr"

    if File.exists? certfile_easyrsa
      msg = OnBoard::System::Command.run <<EOF
cd #{OnBoard::Crypto::EasyRSA::SCRIPTDIR}
. ./vars
export CACERT=#{OnBoard::Crypto::SSL::CACERT}
export CAKEY=#{OnBoard::Crypto::SSL::CAKEY} 
./revoke-full "#{params['name']}"
EOF
    end
    [
        certfile_easyrsa, keyfile_easyrsa, csr_easyrsa,
        certfile, keyfile
    ].each do |file|
      FileUtils.rm(file) if File.exists?(file) or File.symlink?(file) 
    end
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/cert-del',
      :format   => 'html',
      :objects  => {},
      :msg      => msg,
      :title    => 'SSL keys and certificates'
    )
  end

 
end
