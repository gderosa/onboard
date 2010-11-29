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
          unless params[k] and params[k].to_i > 0
            h[k] = v
          end
        end
        params.update h
      end

      def normalize_params!(params)
        params = normalize_params(params)
      end

    end

  end
end
