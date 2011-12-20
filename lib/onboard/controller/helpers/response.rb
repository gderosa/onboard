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

    end
  end
end
