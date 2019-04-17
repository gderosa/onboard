# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      # Auth helpers, from http://www.sinatrarb.com/faq.html#auth
      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end
      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)

        # Rack::Auth::Basic::Request#basic? turns false when OnBoard runs
        # daemonized (via rackup file). So we don't check it.
        #
        if @auth.provided? && @auth.credentials
          if File.exists? OnBoard::Passwd::ADMIN_PASSWD_FILE
            return (
              @auth.credentials[0] == 'admin' &&
              Passwd.check_admin_pass(@auth.credentials[1])
            )
          else
            return @auth.credentials == ['admin', 'admin']
          end
        end
      end
      # there's a before filter in controller.rb

    end
  end
end
