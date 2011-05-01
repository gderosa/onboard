require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    get '/content-filter/dansguardian/init.:format' do
      dg = ContentFilter::DG.new
      # dg.get_status
      format(
        :path     => '/content-filter/dansguardian/init',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: initialize configuration',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        }
      )
    end

    put '/content-filter/dansguardian/init.:format' do
      msg = {}  
      dg = ContentFilter::DG.new
      #dg.get_status
      if params['delete_all'] == 'on'
        FileUtils.rm_r dg.root if File.exists? dg.root
      end
      if params['initialize_config_files']
        msg = dg.write_all 
      end
      format(
        :path     => '/content-filter/dansguardian/init',
        :module   => 'dansguardian',
        :title    => 'DansGuardian: initialize configuration',
        :format   => params[:format],
        :objects  => {
          :dg       => dg
        },
        :msg      => msg
      )
    end

  end
end
