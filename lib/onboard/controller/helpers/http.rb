# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      def parent_path
        "#{File.dirname(request.path_info)}.#{params[:format]}"
      end

      def query_string_merge(h)
        # Rack::Request#GET doesn't play well when :method_ovverride
        # is enabled in Sinatra.
        get_params = Rack::Utils.parse_query(request.query_string)
        Rack::Utils.build_query(
          get_params.merge(h)
        )
      end

      # same interface as ERB::Util
      def url_encode(str)
        Rack::Utils.escape(str)
      end
      def url_decode(str)
        Rack::Utils.unescape(str)
      end

      def current_encoding
        response['Content-Type'] =~ /charset\s*=\s*([^\s;,]+)/
        encname = $1.dup
        begin
          Encoding.find encname
        rescue ArgumentError
          Encoding.find 'utf-8'
        end
      end

    end
  end
end
