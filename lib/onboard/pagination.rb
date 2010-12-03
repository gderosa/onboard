class OnBoard
  module Pagination

    DEFAULTS = {
      :page     =>  1,
      :per_page => 10,
    }

    class << self

      def normalize_params(params)
        h = {}
        DEFAULTS.each_pair do |k, v|
          if params[k] and params[k].to_i > 0
            h[k] = params[k]
          else
            h[k] = v
          end
        end
        return h
      end
      alias normalize normalize_params

    end

  end
end
