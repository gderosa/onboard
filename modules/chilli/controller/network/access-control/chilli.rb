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

    put '/network/access-control/chilli.:format' do
      if params['stop'] =~ /\S/
        iface = params['stop'].strip
        chilli = CHILLI_CLASS.getAll().detect do |x| 
          x.conf['dhcpif'] == iface and x.running?
        end
        msg = chilli.stop if chilli
        sleep 1 # diiiirty!
      elsif params['start'] =~ /\S/
        iface = params['start'].strip
        chilli = CHILLI_CLASS.getAll().detect do |x| 
          x.conf['dhcpif'] == iface and not x.running?
        end
        msg = chilli.start if chilli
      end
      format(
        :module   => 'chilli',
        :path     => '/network/access-control/chilli',
        :format   => params[:format],
        :objects  => CHILLI_CLASS.getAll(),
        :msg      => msg
      )
    end

    post '/network/access-control/chilli.:format' do
      msg = {}
      begin
        chilli = CHILLI_CLASS.create_from_HTTP_request(params)
        chilli.conffile = "#{CHILLI_CLASS::CONFDIR}/current/chilli.conf.#{chilli.conf['dhcpif']}"
        chilli.write_conffile
        raise CHILLI_CLASS::BadRequest, 'Invalid configuration!' unless chilli.validate_conffile # for whatever is not already checked by Chilli::validate_HTTP_creation
        status(201) # HTTP Created
        headers(
            'Location' => 
  "#{request.scheme}://#{request.host}:#{request.port}/network/access-control/chilli/#{chilli.conf['dhcpif']}.#{params[:format]}" 
        )
        msg = {:ok => true}
      rescue CHILLI_CLASS::BadRequest
        status 400
        msg = {:err => $!}
      end
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => CHILLI_CLASS.getAll(),
        :msg => msg
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
