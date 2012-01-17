require 'sinatra/base'

class OnBoard

  class Controller < Sinatra::Base

    # Based on connectors/jqueryFileTree.rb contained in
    # labs.abeautifulsite.net/archived/jquery-fileTree/jquery.fileTree-1.01.zip
    # An adaptation from CGI to Sinatra.
    get '/connectors/jqueryFileTree/:root_id.html' do
      out = ''
      if params['root_id'] == 'files'
        content_type 'text/plain'
        out << params.pretty_inspect
      else
        halt 403, 'Forbidden'
      end
    end

  end

end


