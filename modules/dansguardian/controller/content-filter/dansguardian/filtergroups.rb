require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian/filtergroups.:format' do
      dg = ContentFilter::DG.new
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end

    put '/content-filter/dansguardian/filtergroups.:format' do
      dg = ContentFilter::DG.new
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end
   
  end
end
