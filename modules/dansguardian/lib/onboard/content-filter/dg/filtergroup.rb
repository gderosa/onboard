class OnBoard
  module ContentFilter
    class DG
      class FilterGroup

        attr_reader :conffile, :id, :dansguardian_id
        attr_writer :dansguardian_id

        def initialize(h)
          @conffile         = h[:conffile]
          @id               = h[:id]
          @dansguardian_id  = h[:dansguardian_id]
        end

        def to_h
          {
            'conffile'        => @conffile,
            'id'              => @id,
            'dansguardian_id' => @dansguardian_id
          }
        end

        def to_json(*args); to_h.to_json(*args); end
        def to_yaml(*args); to_h.to_yaml(*args); end

      end
    end
  end
end

