
class OnBoard
  module ContentFilter
    class DG
      module AuthPlugin

        class << self

          def config_file(id)
            "#{DG.root}/authplugins/#{id}.conf"
          end

        end

      end
    end
  end
end
