require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    # Based on connectors/jqueryFileTree.rb contained in
    # labs.abeautifulsite.net/archived/jquery-fileTree/jquery.fileTree-1.01.zip
    # An adaptation from CGI to Sinatra.
    get '/connectors/jqueryFileTree/:root_id.html' do
      root = nil
      out = ''
      if params['root_id'] == 'files' # for future extension
        begin 
          root = ENV['HOME'] + '/files'
          dir = params['dir'].to_s
          path = File.join root, dir

          out << "<ul class=\"jqueryFileTree\" style=\"display:none;\">"

          # chdir() to user requested dir (root + "/" + dir)
          Dir.chdir(File.expand_path(path).untaint)

          # check that our base path still begins with root path
          if Dir.pwd[0,root.length] == root

            #loop through all directories
            Dir.glob("*") do |x|
              if not File.directory?(x.untaint)
                next
              end
              out << "<li class=\"directory collapsed\"><a href=\"#\" rel=\"#{dir}#{x}/\">#{x}</a></li>"
            end
            
            #loop through all files
            Dir.glob("*") do |x|
              if not File.file?(x.untaint) 
                next
              end
              ext = File.extname(x)[1..-1]
              out << "<li class=\"file ext_#{ext}\"><a href=\"#\" rel=\"#{dir}#{x}\">#{x}</a></li>"
            end
            
            out << "</ul>"

            return out

          else
            forbidden
          end

        rescue Errno::ENOENT
          not_found
        end

      else
        not_found
      end

    end

  end

end


