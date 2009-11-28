autoload :FileUtils,  'fileutils'
autoload :OpenSSL,    'onboard/extensions/openssl'

class OnBoard
  class Controller  

    get '/crypto/ssl/ca/ca.crt' do
      # decode it, for better human readability (but it's still a valid cert.)
      c = ::OpenSSL::X509::Certificate.new(File.read(Crypto::SSL::CACERT))
      content_type "application/x-x509-ca-cert"
      attachment "ca.crt" # avoid auto-import into browser
      c.to_text + c.to_pem
    end

    get '/crypto/ssl/certs/:name.crt' do
      certfile = "#{Crypto::SSL::CERTDIR}/#{params[:name]}.crt"
      if File.exists? certfile
        c = ::OpenSSL::X509::Certificate.new(File.read(certfile))
        if c.ca?
          content_type "application/x-x509-ca-cert" 
        else
          content_type "application/x-x509-cert" 
              # What is the correct MIME-type for an X509 cert. which is NOT
              # a CA?
        end
        attachment "#{params[:name]}.crt"
        c.to_text + c.to_pem
      else
        not_found
      end
    end

    get '/crypto/ssl/certs/private/:name.key' do
      keyfile = "#{Crypto::SSL::KEYDIR}/#{params[:name]}.key"
      if File.exists? keyfile
        content_type "application/x-pem-key"
        attachment "#{params[:name]}.key"
        File.read keyfile
      else
        not_found
      end
    end

    post '/crypto/ssl/certs.:format' do
      target = nil
      msg = {:ok => true}
      if params['certificate'].respond_to? :[] 
        begin
          cert = OpenSSL::X509::Certificate.new(
              params['certificate'][:tempfile].read
          )
          cn = cert.to_h['subject']['CN']
          cn_escaped = cn.gsub('/', '===slash===')
          target = "#{Crypto::SSL::CERTDIR}/#{cn_escaped}.crt"
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
        rescue OpenSSL::X509::CertificateError
          status(400)
          msg = {:ok => false, :err => $!}
        end
        if params['private_key'].respond_to? :[]
          # priv. key verification is not done here...
          File.open("#{Crypto::SSL::KEYDIR}/#{cn}.key", 'w') do |f|
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


  end
end
