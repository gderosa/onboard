require 'sinatra/base'
require 'onboard/content-filter/dg'

class OnBoard
  class Controller < Sinatra::Base

    %w{
      /content-filter/dansguardian/lists/*/*/*.:format
      /content-filter/dansguardian/lists/*/*.:format
    }.each do |path| # Order matters.
      #
      # Example: /content-filter/dansguardian/lists/banned/sites/sub1/sub2.html
      # You get params[:splat] #=> ["banned", "sites", "sub1/sub2" ]
      #
      # Example: /content-filter/dansguardian/lists/banned/sites.html
      # You get params[:splat] #=> ["banned", "sites"]
      get path do
        begin
          format(
            :path     => '/content-filter/dansguardian/lists',
            :module   => 'dansguardian',
            :title    => 
                "DansGuardian: #{ContentFilter::DG::ManagedList.title(
                    params[:splat]
                )}",
            :format   => params[:format],
            :objects  => ContentFilter::DG::ManagedList.ls(
                params[:splat].join('/')
            ) 
          )
        rescue Errno::ENOENT
          not_found
        end
      end

    end
   
  end
end
