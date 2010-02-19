require 'sinatra/base'

require 'onboard/network/access-control/chilli'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/access-control/chilli.:format' do
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => CHILLI_CLASS.getAll()
      )
    end

    post '/network/access-control/chilli.:format' do
      chilli = CHILLI_CLASS.create_from_HTTP_request(params)
      chilli.conffile = "#{CHILLI_CLASS::CONFDIR}/current/chilli.conf.#{chilli.conf['dhcpif']}"
      chilli.write_conffile
      status(201) # HTTP Created
      headers(
          'Location' => 
"#{request.scheme}://#{request.host}:#{request.port}/network/access-control/chilli/#{chilli.conf['dhcpif']}.#{params[:format]}" 
      )
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => CHILLI_CLASS.getAll()  
      )
    end

    get '/network/access-control/chilli/:ifname.:format' do
      all = CHILLI_CLASS.getAll()
      chilli_object = all.detect{|x| x.conf['dhcpif'] == params[:ifname]}
      if chilli_object
        format(
          :module => 'chilli',
          :path => '/network/access-control/chilli/ifconfig',
          :format => params[:format],
          :objects  => chilli_object 
        )
      else
        not_found
      end
    end
   
  end

end
