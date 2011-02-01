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
      ContentFilter::DG.new.write_all if
          params['initialize_config_files']
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

  end
end
