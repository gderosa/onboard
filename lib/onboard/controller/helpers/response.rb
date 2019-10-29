# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      def multiple_choices(h={})
        status(300)
        paths = []
        formats = h[:formats] || @@formats
        formats.each do |fmt|
          paths << request.path_info.sub(/\.[^\.]*$/, '.' + fmt)
        end
        formats.each do |fmt|
          args_h = {
            :path     => '300',
            :format   => fmt,
            :formats  => formats
          }
          if request.env["HTTP_ACCEPT"] [fmt] # "contains"
            return format args_h
          end
          format args_h
        end
      end

      def forbidden
        status 403
        format :path => '403'
      end

      # http://www.sinatrarb.com/intro#Triggering%20Another%20Route
      # This would have saved lots of duplicated code!
      #
      # Also, save the original environment for proper operation in
      # /views/_navbar.html.erb (and possibly other stuff).
      before do
        @real_request = @original_request = @actual_request ||= request.dup
      end
      def same_as_get
        status, headers, body = call! env.merge("REQUEST_METHOD" => 'GET')
        [status, headers, body]
      end
      alias same_as_GET same_as_get

    end
  end
end
