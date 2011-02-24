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
        formats = @@formats.dup
        begin
          object = ContentFilter::DG::ManagedList.get(
            params[:splat].join('/'), :file_encoding => params['file_encoding']
          )
          object.read! if object.respond_to? :read!
          view_path = case object
                 when ContentFilter::DG::ManagedList::Dir
                   '/content-filter/dansguardian/lists/dir'
                 when ContentFilter::DG::ManagedList::List
                   formats = ['html', 'raw'] # side effect
                   '/content-filter/dansguardian/lists/list'
                 else
                   raise TypeError, "I would expect a ContentFilter::DG::ManagedList::(File|List) object, got #{object.inspect}"
                 end
          if 
              params[:format] == 'raw' and 
              object.is_a? ContentFilter::DG::ManagedList::List
            attachment File.basename params[:splat].last
            send_file object.absolute_path, :type => 'text/plain'
          else
            format(
              :path     => view_path,
              :module   => 'dansguardian',
              :title    => 
                  "DansGuardian: #{ContentFilter::DG::ManagedList.title(
                      params[:splat]
                  )}",
              :format   => params[:format],
              :formats  => formats,
              :objects  => object
            )
          end
          rescue Errno::ENOENT
          not_found
        end
      end

      put path do
        begin
          object = ContentFilter::DG::ManagedList.get(
            params[:splat].join('/'), :file_encoding => params['file_encoding']
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
      
      post path do 
        basedir = File.realpath ContentFilter::DG::ManagedList.absolute_path(
          params[:splat].join('/') 
        )
        not_found unless File.directory? basedir

        # Create new file or directory
        case params['new'] 
        when 'directory'
          FileUtils.mkdir "#{basedir}/#{params['name']}" 
        when 'file'
          File.open("#{basedir}/#{params['name']}", 'w') {} 
        when /^copy_from:(.*)/
          copy_from_basename = File.basename $1
          FileUtils.cp(
              "#{basedir}/#{copy_from_basename}", 
              "#{basedir}/#{params['name']}"
          )
        end

        ## File upload
        #
        # but preserve destination .Includes
        include_re = /^[\s#]*\.Include<.*>/ # even commented
        if params['upload']
          preserve_includes = ''
          if params['rename'] =~ /\S/
            dest = "#{basedir}/#{params['rename']}"
          else
            dest = "#{basedir}/#{params['upload'][:filename]}" 
          end
          if File.exists? dest
            f = File.open dest, 'r'
            preserve_includes = f.grep(include_re).join
            f.close
          end
          File.open dest, 'w' do |o|
            File.foreach params['upload'][:tempfile] do |line|
              next if line =~ include_re
              o.write line
            end
            o.write preserve_includes
          end
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
