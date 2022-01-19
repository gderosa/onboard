# OnBoard::Crypto::SSL is part of the core, while OnBoard::Crypto::EasyRSA
# is in a module and is just one of the ways to create/view certs via
# helper scripts.

require 'sinatra/base'

require 'onboard/system/command'
require 'onboard/crypto/easy-rsa'
require 'onboard/crypto/ssl'
require 'onboard/crypto/ssl/multi'
require 'onboard/crypto/ssl/pki'

class OnBoard::Controller < Sinatra::Base

  get '/crypto/easy-rsa.:format' do
    OnBoard::Crypto::EasyRSA::Multi.handle_legacy
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/multi',
      :format   => params[:format],
      :objects  => OnBoard::Crypto::SSL::Multi.get_pkis(),
      :title    => 'Public Key Infrastructures (PKIs)'
    )
  end

  post '/crypto/easy-rsa.:format' do
    params['pkiname'].strip!
    params['pkiname'].gsub! /\s/, '_'
    OnBoard::Crypto::EasyRSA::Multi.add_pki(params['pkiname'])
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa/multi',
      :format   => params[:format],
      :objects  => OnBoard::Crypto::SSL::Multi.get_pkis(),
      :title    => 'Public Key Infrastructures (PKIs)'
    )
  end

  get '/crypto/easy-rsa/:pkiname.:format' do
    ssl_pki = OnBoard::Crypto::SSL::PKI.new params[:pkiname]
    not_found unless (ssl_pki.exists? or ssl_pki.system?)
    easyrsa_pki = OnBoard::Crypto::EasyRSA::PKI.new params[:pkiname]
    # create Diffie-Hellman params if they don't exist
    dsaparam_above = 2048
    if settings.development?  # Sinatra
      dsaparam_above = 1024
    end
    OnBoard::Crypto::SSL::KEY_SIZES.each do |n|
      # One thread at a time for each key size.
      # If there is another PKI building DH params of the same key size,
      # it will wait...
      Thread.new do
        easyrsa_pki.dh_mutex(n).synchronize do
          unless ssl_pki.dh_exists?(n)
            easyrsa_pki.create_dh(n, :dsaparam_above => dsaparam_above)
          end
        end
      end
    end
    sleep 0.1 # this is diiiiirty!
    format(
      :module   => 'easy-rsa',
      :path     => '/crypto/easy-rsa',
      :format   => params[:format],
      :objects  => easyrsa_pki.getAll(),
      :title    => 'SSL keys and certificates'
    )
  end

  delete '/crypto/easy-rsa/:pkiname.:format' do
    easyrsa_pki = OnBoard::Crypto::EasyRSA::PKI.new params[:pkiname]
    ssl_pki = OnBoard::Crypto::SSL::PKI.new params[:pkiname]
    not_found unless easyrsa_pki.exists? or ssl_pki.exists?
    # TODO: handle errors
    easyrsa_pki.delete!
    ssl_pki.delete!
    redirect File.join request.path_info, "../../easy-rsa.#{params[:format]}"
  end

  get '/crypto/easy-rsa/:pkiname/ca/index.txt' do
    easyrsa_pki = OnBoard::Crypto::EasyRSA::PKI.new params[:pkiname]
    index_txt = easyrsa_pki.keydir + '/index.txt'
    if File.exists? index_txt
      content_type 'text/plain'
      attachment "index.txt"
      File.read index_txt
    else
      not_found
    end
  end

=begin
  # CRL buggy even with single PKI
  get '/crypto/easy-rsa/default/ca/crl.:sslformat' do
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
=end

  delete '/crypto/easy-rsa/:pkiname/ca.:format' do
    easyrsa_pki = OnBoard::Crypto::EasyRSA::PKI.new params[:pkiname]
    ssl_pki = OnBoard::Crypto::SSL::PKI.new params[:pkiname]
    msg = OnBoard::System::Command.run <<EOF
cd #{OnBoard::Crypto::EasyRSA::SCRIPTDIR}
export KEY_DIR=#{easyrsa_pki.keydir}
./clean-all
EOF
    FileUtils.rm ssl_pki.cacertpath
    FileUtils.rm ssl_pki.cakeypath

    redirection = "/crypto/easy-rsa/#{params[:pkiname]}.#{params['format']}"
    status(303)                       # HTTP "See Other"
    headers('Location' => redirection)
    format(
      :path     => '/303',
      :format   => params[:format],
      :title    => 'SSL keys and certificates: PKI: ' + params[:pkiname]
    )
  end

  post '/crypto/easy-rsa/:pkiname/ca.:format' do
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
  post '/crypto/easy-rsa/:pkiname/certs.:format' do
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
  delete '/crypto/easy-rsa/:pkiname/certs/:name.crt' do
    pkiname = params[:pkiname]
    certname = params[:name]
    msg = {:ok => true}
    ssl_pki = OnBoard::Crypto::SSL::PKI.new(pkiname)
    easyrsa_pki = OnBoard::Crypto::EasyRSA::PKI.new(pkiname)
    certfile = File.join ssl_pki.certdir, "#{certname}.crt"
    keyfile = File.join ssl_pki.certdir, 'private', "#{certname}.key"
    certfile_easyrsa = File.join easyrsa_pki.keydir, "#{certname}.crt"
    keyfile_easyrsa = File.join easyrsa_pki.keydir, "#{certname}.key"
    csr_easyrsa = File.join easyrsa_pki.keydir, "#{certname}.csr"

    if File.exists? certfile_easyrsa
      msg = OnBoard::System::Command.run <<EOF
cd #{OnBoard::Crypto::EasyRSA::SCRIPTDIR}
. ./vars
export CACERT=#{ssl_pki.cacertpath}
export CAKEY=#{ssl_pki.cakeypath}
./revoke-full "#{certname}"
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
