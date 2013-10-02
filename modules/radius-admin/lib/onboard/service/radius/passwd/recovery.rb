class OnBoard
  module Service
    module RADIUS
      class Passwd
        class Recovery

          autoload :Config, 'onboard/service/radius/passwd/recovery/config' 

          include Configurable

          def substitute_text(text)
            text.
                gsub('-USER-', username).
                gsub('-PASSWORD-', password)
          end

          def from
            config['mail']['from']
          end

          def subject
            text = config['mail']['subject'] || ''
            substitute_text text
          end

          def body
            text = config['mail']['body'] || ''
            substitute_text text
          end

        end
      end
    end
  end
end
