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
      running = Network::AP::running?(params)
      # TODO: DRY
      res_data = Network::AP::get_config(params[:ifname]).merge({
        'run' => running,
        'logfile' => Network::AP::logfile(params[:ifname])
      })
      format(
        :module => 'ap',
        :path => '/network/ap/if',
        :format => params[:format],
        :objects  => res_data,
        :title => "Wireless Access Point: #{params[:ifname]}"
      )
    end

    put '/network/ap/:ifname.:format' do
      Network::AP::set_config(params[:ifname], params)
      msg = Network::AP::start_stop(params)
      sleep 1
      running = Network::AP::running?(params)
      # TODO: DRY
      res_data = Network::AP::get_config(params[:ifname]).merge({
        'run' => running,
        'logfile' => Network::AP::logfile(params[:ifname])
      })
      format(
        :module => 'ap',
        :path => '/network/ap/if',
        :format => params[:format],
        :objects  => res_data,
        :msg => msg,
        :title => "Wireless Access Point: #{params[:ifname]}"
      )
    end

  end
end

