# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      def paginator(h)
        partial(
          :path     => '_paginator',
          :locals   => h
        )
      end

      def use_pagination_defaults()
        params.update OnBoard::Pagination.normalize(params)
      end

    end
  end
end
