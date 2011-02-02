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

    get '/content-filter/dansguardian/filtergroups.:format' do
      dg = ContentFilter::DG.new
      dg.get_filtergroups
      format(
        :path     => '/content-filter/dansguardian/filtergroups',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: Filter Groups',
        :format   => params[:format],
        :objects  => dg.filtergroups
      )
    end

    put '/content-filter/dansguardian.:format' do
      msg = {}  
      dg = ContentFilter::DG.new
      dg.get_status
      if params['initialize_config_files']
        msg = dg.write_all 
      else
        msg = dg.start_stop(params)
        dg.get_status
      end
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
