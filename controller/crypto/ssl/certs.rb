autoload :FileUtils,  'fileutils'
autoload :OpenSSL,    'onboard/extensions/openssl'

class OnBoard
  class Controller  

    # A WebService client does not need an entity-body (headers and Status
    # will suffice), so html is fine as well, since it will be ignored...
    delete '/crypto/ssl/certs/:name.crt' do
      msg = {}
      certfile = "#{Crypto::SSL::CERTDIR}/#{params[:name]}.crt"
      keyfile = "#{Crypto::SSL::CERTDIR}/private/#{params[:name]}.key"
      if File.exists? certfile
        begin
          FileUtils.rm certfile
          FileUtils.rm keyfile if File.exists? keyfile
          msg = {:ok => true}
        rescue
          msg = {:ok=> false, :err => $!} 
          status(500) 
        end
        msg[:ok] = true if msg[:ok].nil?
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

    post '/crypto/ssl/certs.:format' do
      target = nil
      msg = {:ok => true} 
      begin
        cert = OpenSSL::X509::Certificate.new(
            params['certificate'][:tempfile].read
        )
        cn = cert.to_h['subject']['CN']
        target = "#{Crypto::SSL::CERTDIR}/#{cn}.crt"
        if File.readable? target # already exists
          begin # check if it's valid
            OpenSSL::X509::Certificate.new(File.read target)
            status(409)
            msg = {
              :ok => false, 
              :err => "A certificate with the same COMMON NAME (#{cn}) and/or filename already exists!"
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
      params['certificate'][:tempfile].unlink
      format(
        :path     => '/crypto/ssl/cert_create',
        :format   => params[:format],
        :objects  => nil,
        :msg      => msg
      )
    end


  end
end
