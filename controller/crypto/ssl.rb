require 'fileutils'

require 'onboard/extensions/openssl'

require 'onboard/crypto/ssl/pki'


class OnBoard
  class Controller

    get '/crypto/ssl/:pkiname/ca/ca.crt' do
      ssl_pki = OnBoard::Crypto::SSL::PKI.new params[:pkiname]
      # decode it, for better human readability (but it's still a valid cert.)
      c = ::OpenSSL::X509::Certificate.new(File.read(ssl_pki.cacertpath))
      content_type "application/x-x509-ca-cert"
      attachment "ca.crt" # avoid auto-import into browser
      c.to_text + c.to_pem
    end

    get '/crypto/ssl/:pkiname/certs/:name.crt' do
      pkiname = params[:pkiname]
      certname = params[:name]
      ssl_pki = Crypto::SSL::PKI.new(pkiname)
      certfile = "#{ssl_pki.certdir}/#{certname}.crt"
      if File.exists? certfile
        c = ::OpenSSL::X509::Certificate.new(File.read(certfile))
        if c.ca?
          content_type "application/x-x509-ca-cert"
        else
          content_type "application/x-x509-cert"
              # What is the correct MIME-type for an X509 cert. which is NOT
              # a CA?
        end
        attachment "#{certname}.crt"
        c.to_text + c.to_pem
      else
        not_found
      end
    end

=begin
    # CRL support has been buggy on single PKI too...
    get '/crypto/ssl/:pkiname/CRLs/:name.crl.?:sslformat?' do
      params[:sslformat] = 'pem' unless params[:sslformat]
      crlfile = "#{Crypto::SSL::CERTDIR}/#{params[:name]}.crl"
      if File.exists? crlfile
        # TODO: which is the right MIME type for PEM and DER format?
        case params[:sslformat]
        when 'pem'
          content_type 'application/pkix-crl'
          attachment "#{params[:name]}.crl.pem"
          OpenSSL::X509::CRL.new(File.read crlfile).to_text + # hum. read. part
          OpenSSL::X509::CRL.new(File.read crlfile).to_pem  # BEGIN--END PEM
        when 'der'
          content_type 'application/x-x509-crl'
          attachment "#{params[:name]}.crl.der"
          OpenSSL::X509::CRL.new(File.read crlfile).to_der  # binary format
        else
          not_found # TODO: Multiple Choice, appropriately
        end
      else
        not_found
      end
    end
=end

    get '/crypto/ssl/:pkiname/certs/private/:name.key' do
      keyfile = "#{OnBoard::Crypto::SSL::PKI.new(params[:pkiname]).keydir}/#{params[:name]}.key"
      if File.exists? keyfile
        content_type "application/x-pem-key"
        attachment "#{params[:name]}.key"
        File.read keyfile
      else
        not_found
      end
    end

    # Certificate upload
    post '/crypto/ssl/:pkiname/certs.:format' do
      target = nil
      msg = {:ok => true}
      ssl_pki = OnBoard::Crypto::SSL::PKI.new params[:pkiname]
      if params['certificate'].respond_to? :[]
        begin
          cert = OpenSSL::X509::Certificate.new(
              params['certificate'][:tempfile].read
          )
          cn = cert.to_h['subject']['CN']
          raise OnBoard::Crypto::SSL::PKI::ArgumentError,
              'Cannot find subject\'s Common Name' if not cn
          cn_escaped = cn.gsub('/', Crypto::SSL::PKI::SLASH_FILENAME_ESCAPE)
          FileUtils.mkdir_p ssl_pki.certdir
          target = "#{ssl_pki.certdir}/#{cn_escaped}.crt"
          if File.readable? target # already exists
            begin # check if it's valid
              OpenSSL::X509::Certificate.new(File.read target)
              status(409)
              msg = {
                :ok => false,
                :err_html => "A certificate with the same Common Name &ldquo;<code>#{cn}</code>&rdquo; already exists!"
              }
            rescue OpenSSL::X509::CertificateError # otherwise you can overwrite
              File.open(target, 'w') do |f|
                # the same format created by easy-rsa...
                f.write cert.to_text # human readable data
                f.write cert.to_s # the certificate itself between BEGIN-END tags
              end
            end
          else
            File.open(target, 'w') do |f|
              # the same format created by easy-rsa...
              f.write cert.to_text # human readable data
              f.write cert.to_s # the certificate itself between BEGIN-END tags
            end
          end
        rescue OpenSSL::X509::CertificateError, Crypto::SSL::PKI::ArgumentError
          status(400)
          msg = {:ok => false, :err => $!}
        end
        if params['private_key'].respond_to? :[]
          # priv. key verification is not done here...
          FileUtils.mkdir_p ssl_pki.keydir
          File.open("#{ssl_pki.keydir}/#{cn}.key", 'w') do |f|
            f.write File.read params['private_key'][:tempfile]
          end
          params['private_key'][:tempfile].unlink
        end
        params['certificate'][:tempfile].unlink
      else
        status(400)
        msg = {
          :ok => false,
          :err => "No certificate was sent.",
          :err_html => "No certificate was sent."
        }
      end
      format(
        :path     => '/crypto/ssl/cert_create',
        :format   => params[:format],
        :objects  => nil,
        :msg      => msg
      )
    end

=begin
    # CRL upload: buggy since single-PKI versions
    post '/crypto/ssl/:pkiname/CRLs.:format' do
      target = nil
      msg = {:ok => true}
      if params['CRL'].respond_to? :[]
        begin
          crl = OpenSSL::X509::CRL.new(
              params['CRL'][:tempfile].read
          )
          cn = crl.issuer.to_h['CN']
          raise OnBoard::Crypto::SSL::ArgumentError, 'Cannot find subject\'s Common Name' if not cn
          cn_escaped = cn.gsub('/', Crypto::SSL::SLASH_FILENAME_ESCAPE)
          # NOTE: VERY simple filename/CN match :-P
          raise OnBoard::Crypto::SSL::Conflict, 'Cannot find matching CA Certificate. You should upload it first.' unless File.exists? "#{Crypto::SSL::CERTDIR}/#{cn_escaped}.crt"
          target = "#{Crypto::SSL::CERTDIR}/#{cn_escaped}.crl"
          File.open(target, 'w') do |f|
            # Force storage in PEM format, maybe less efficient but
            # but easier to debug.
            # It's the same format created by easy-rsa...
            f.write crl.to_text # human readable data
            f.write crl.to_s # the CRL itself between BEGIN-END tags
          end
        rescue OpenSSL::X509::CRLError, OnBoard::Crypto::SSL::ArgumentError
          status(400)
          msg = {:ok => false, :err => $!}
        rescue OnBoard::Crypto::SSL::Conflict
          status(409)
          msg = {:ok => false, :err => $!, :err_html => $!.to_s}
        end
        params['CRL'][:tempfile].unlink
      else
        status(400)
        msg = {
          :ok => false,
          :err => "No CRL was sent.",
          :err_html => "No CRL was sent."
        }
      end
      format(
        :path     => '/crypto/ssl/crl_create',
        :format   => params[:format],
        :objects  => nil,
        :msg      => msg
      )
    end
=end

  end
end
