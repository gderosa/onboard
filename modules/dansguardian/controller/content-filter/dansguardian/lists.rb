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
          object = ContentFilter::DG::ManagedList.get(
            params[:splat].join('/')
          )
          object.read! if object.respond_to? :read!
          view_path = case object
                 when ContentFilter::DG::ManagedList::Dir
                   '/content-filter/dansguardian/lists/dir'
                 when ContentFilter::DG::ManagedList::List
                   '/content-filter/dansguardian/lists/list'
                 else
                   raise TypeError, "I would expect a ContentFilter::DG::ManagedList::(File|List) object, got #{object.inspect}"
                 end
          format(
            :path     => view_path,
            :module   => 'dansguardian',
            :title    => 
                "DansGuardian: #{ContentFilter::DG::ManagedList.title(
                    params[:splat]
                )}",
            :format   => params[:format],
            :objects  => object
          )
        rescue Errno::ENOENT
          not_found
        end
      end

      put path do
        begin
          object = ContentFilter::DG::ManagedList.get(
            params[:splat].join('/')
          )
          object.update!(params)
          object.read! if object.respond_to? :read!
          view_path = case object
                 when ContentFilter::DG::ManagedList::Dir
                   '/content-filter/dansguardian/lists/dir'
                 when ContentFilter::DG::ManagedList::List
                   '/content-filter/dansguardian/lists/list'
                 else
                   raise TypeError, "I would expect a ContentFilter::DG::ManagedList::(File|List) object, got #{object.inspect}"
                 end
          format(
            :path     => view_path,
            :module   => 'dansguardian',
            :title    => 
                "DansGuardian: #{ContentFilter::DG::ManagedList.title(
                    params[:splat]
                )}",
            :format   => params[:format],
            :objects  => object
          )
        rescue Errno::ENOENT
          not_found
        end
      end   

    end
   
  end
end
