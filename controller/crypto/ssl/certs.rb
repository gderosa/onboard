require 'fileutils'

class OnBoard
  class Controller  

    # A WebService client does not need an entity-body (headers and Status
    # will suffice), so html is fine as well, since it will be ignored...
    delete '/crypto/ssl/certs/:name.crt' do
      msg = {}
      certfile = "#{Crypto::SSL::CERTDIR}/#{params[:name]}.crt"
      keyfile = "#{Crypto::SSL::CERTDIR}/private/#{params[:name]}.key"
      if File.exists? certfile
        #begin
          FileUtils.rm certfile
          FileUtils.rm keyfile if File.exists? keyfile
        #  msg = {:ok => true}
        #rescue
        #  msg = {:ok=> false, :err => $!} 
        #  status(500) 
        #end
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
end
