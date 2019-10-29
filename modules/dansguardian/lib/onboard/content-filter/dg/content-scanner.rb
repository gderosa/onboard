
class OnBoard
  module ContentFilter
    class DG
      module ContentScanner

        class << self

          def config_file(id)
            "#{DG.root}/contentscanners/#{id}.conf"
          end

        end

      end
    end
  end
end
