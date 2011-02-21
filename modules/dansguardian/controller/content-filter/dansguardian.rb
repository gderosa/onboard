require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian.:format' do
      dg = ContentFilter::DG.new
      dg.get_status
      format(
        :path     => '/content-filter/dansguardian',
        :module   => 'dansguardian',
        :title    => 'DansGuardian Web Content Filtering',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end

    put '/content-filter/dansguardian.:format' do
      msg = {}  
      dg = ContentFilter::DG.new
      dg.get_status
      if params['start'] or params['stop'] or params['restart']
        msg = dg.start_stop(params)
      end

      dg.edit_main_config!(params)

      dg.get_status
      format(
        :path     => '/content-filter/dansguardian',
        :module   => 'dansguardian',
        :title    => 'DansGuardian Web Content Filtering',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        },
        :msg      => msg
      )
    end

  end
end
