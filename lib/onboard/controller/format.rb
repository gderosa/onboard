require 'sinatra/base'

require 'onboard/extensions/sinatra/base'
require 'onboard/extensions/sinatra/templates'

class OnBoard
  class Controller < ::Sinatra::Base

    use Rack::PostBodyContentTypeParser

    @@formats = %w{html json} # order matters
    @@formats << 'rb' if development? or test?

    # http://sinatrarb.com/intro.html @ 'Triggering Another Route'

    # /api/v1/foo/bar -> /foo/bar.json

    # TODO: move to a controller/api.rb ?

    def api_route_trigger(subpath)
      status, headers, body = call! env.merge(
        "ORIGINAL_PATH_INFO" => request.path,
        "PATH_INFO" => '/' + subpath + '.json'
      )
      [status, headers, body]
    end

    get %r{/api/v1/(.*)} do |subpath|
      api_route_trigger subpath
    end

    post %r{/api/v1/(.*)} do |subpath|
      api_route_trigger subpath
    end

    put %r{/api/v1/(.*)} do |subpath|
      api_route_trigger subpath
    end

    delete %r{/api/v1/(.*)} do |subpath|
      api_route_trigger subpath
    end

  end
end

