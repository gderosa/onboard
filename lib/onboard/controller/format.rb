require 'sinatra/base'

require 'onboard/extensions/sinatra/base'

class OnBoard
  class Controller < ::Sinatra::Base

    # TODO: it's deprecated: https://www.rubydoc.info/github/rack/rack-contrib/Rack/PostBodyContentTypeParser
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

    get %r{(/api/.*)/} do
      redirect params['captures'][0]
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

