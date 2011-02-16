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
      
      post path do # create directory
        basedir = File.realpath ContentFilter::DG::ManagedList.absolute_path(
          params[:splat].join('/') 
        )
        not_found unless File.directory? basedir
        case params['new'] 
        when 'directory'
          FileUtils.mkdir "#{basedir}/#{params['name']}" 
        when 'file'
          File.open("#{basedir}/#{params['name']}", 'w') {} 
        end

        # read
        object  = ContentFilter::DG::ManagedList.get(
          params[:splat].join('/')
        )
        format(
          :path     => '/content-filter/dansguardian/lists/dir',
          :module   => 'dansguardian',
          :title    => 
              "DansGuardian: #{ContentFilter::DG::ManagedList.title(
                  params[:splat]
              )}",
          :format   => params[:format],
          :objects  => object
        )       
      end 

    end

    delete '/content-filter/dansguardian/lists/*/*/*.:format' do
      listobject = ContentFilter::DG::ManagedList.get(
        params[:splat].join('/')
      )
      listobject.delete_files! if params['confirm'] == 'on'
      status 303 # HTTP See Other
      headers 'Location' => # redirect to parent dir 
          "#{File.dirname(request.path_info)}.#{params[:format]}"
    end
   
  end
end
