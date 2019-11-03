require 'sinatra/base'

require 'onboard/network/ap'

class OnBoard
  class Controller < Sinatra::Base

    get '/network/ap.:format' do
      format(
        :module => 'ap',
        :path => '/network/ap',
        :format => params[:format],
        :objects  => [],
        :title => "Wireless Access Point"
      )
    end

    get '/network/ap/:ifname.:format' do
      format(
        :module => 'ap',
        :path => '/network/ap/if',
        :format => params[:format],
        :objects  => [],
        :title => "Wireless Access Point: #{params[:ifname]}"
      )
    end

    put '/network/ap/:ifname.:format' do
      msg = Network::AP::set_config(params[:ifname], params)
      format(
        :module => 'ap',
        :path => '/network/ap/if',
        :format => params[:format],
        :objects  => [],
        :msg => msg,
        :title => "Wireless Access Point: #{params[:ifname]}"
      )
    end

  end
end

