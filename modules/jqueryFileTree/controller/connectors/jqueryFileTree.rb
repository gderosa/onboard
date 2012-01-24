require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    # Based on connectors/jqueryFileTree.rb contained in
    # labs.abeautifulsite.net/archived/jquery-fileTree/jquery.fileTree-1.01.zip
    #
    # An adaptation from CGI to Sinatra.
    #
    # Also, a "protocol specification" is at
    # http://www.abeautifulsite.net/blog/2008/03/jquery-file-tree/#custom_connectors
    #
    get '/connectors/jqueryFileTree/:root_id.html' do
      root = nil
      out = ''
      if params['root_id'] == 'files' # for future extension
        begin 
          root = File.realpath(ENV['HOME']) + '/files'
          dir = params['dir'].to_s
          path = File.join root, dir

          out << "<ul class=\"jqueryFileTree\" style=\"display:none;\">"

          # chdir() to user requested dir (root + "/" + dir)
          Dir.chdir(File.expand_path(path).untaint)

          # check that our base path still begins with root path
          if Dir.pwd[0,root.length] == root

            #loop through all directories
            Dir.glob("*").sort.each do |x|
              if not File.directory?(x.untaint)
                next
              end
              out << "<li class=\"directory collapsed\"><a href=\"#\" rel=\"#{dir}#{x}/\">#{x}</a></li>"
            end
            
            #loop through all files
            Dir.glob("*").sort.each do |x|
              if not File.file?(x.untaint) 
                next
              end
              ext = File.extname(x)[1..-1]
              out << "<li class=\"file ext_#{ext}\"><a href=\"#\" rel=\"#{dir}#{x}\">#{x}</a></li>"
            end
            
            out << "</ul>"

            return out

          else # Sorry, we can't be ReSTful
            return '<span class="error forbidden">Forbidden</span>'
          end

        rescue Errno::ENOENT
          return '<span class="error not_found">Not Found</span>'
        end

      else
        return '<span class="error not_found">Not Found</span>'
      end

    end

    # POST is actually required by jqueryFileTree: a GET route is just 
    # there to naively debug with a browser :-P
    post '/connectors/jqueryFileTree/:root_id.html' do
      same_as_GET
    end

  end

end


