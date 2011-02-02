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
      end
    end
  end
end

