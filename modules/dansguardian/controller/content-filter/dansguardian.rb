require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian.:format' do
      format(
        :path     => '/content-filter/dansguardian',
        :module   => 'dansguardian',
        :title    => 'DansGuardian Web Content Filtering',
        :format   => params[:format],
        :objects  => []
      )
    end

    put '/content-filter/dansguardian.:format' do
      ContentFilter::DG.new.write_all
      format(
        :path     => '/content-filter/dansguardian',
        :module   => 'dansguardian',
        :title    => 'DansGuardian Web Content Filtering',
        :format   => params[:format],
        :objects  => []
      )
    end

  end
end
