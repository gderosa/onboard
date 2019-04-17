require 'sinatra/base'

require 'onboard/extensions/sinatra/base'
require 'onboard/extensions/sinatra/templates'

class OnBoard
  class Controller < ::Sinatra::Base

    use Rack::PostBodyContentTypeParser

    @@formats = %w{html json} # order matters
    @@formats << 'rb' if development? or test?

    # http://sinatrarb.com/intro.html @ 'Triggering Another Route'
    get %r{/api/v1/(.*)} do |subpath|
      status, headers, body = call! env.merge("PATH_INFO" => '/' + subpath + '.json')
      [status, headers, body]
    end

    post %r{/api/v1/(.*)} do |subpath|
      status, headers, body = call! env.merge("PATH_INFO" => '/' + subpath + '.json')
      [status, headers, body]
    end

    put %r{/api/v1/(.*)} do |subpath|
      status, headers, body = call! env.merge("PATH_INFO" => '/' + subpath + '.json')
      [status, headers, body]
    end

    delete %r{/api/v1/(.*)} do |subpath|
      status, headers, body = call! env.merge("PATH_INFO" => '/' + subpath + '.json')
      [status, headers, body]
    end

  end
end

