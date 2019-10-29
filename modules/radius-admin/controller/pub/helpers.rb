
class OnBoard
  class Controller < Sinatra::Base

    helpers do

      def hotspot_redirect(opts={})
        # extracted/generalized from controller/pub/services/radius/signup.rb
        # @ post '/pub/services/radius/signup.html'
        opts[:time] ||= 4
        if \
                params['redirect'] =~ /^https?:\/\/[a-z]+.*\.[a-z]+/i and \
            not params['redirect'] =~ /hotspot/i
          headers(
            "Refresh" => "#{opts[:time]};url=#{params['redirect']}"
          )
        end
      end

    end

  end
end
