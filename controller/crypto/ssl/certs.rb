class OnBoard
  class Controller  
    # A WebService client does not need an entity-body (headers and Status
    # will suffice), so html is fine as well, since it will be ignored...
    delete '/crypto/ssl/certs/:name.crt' do
      format(
        :path => '/crypto/ssl/cert_del',
        :format => 'html',
        :objects => {},
        :msg => {:ok => true} 
      )
    end
  end
end
