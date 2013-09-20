require 'onboard/service/mail/constants'

class OnBoard
  module Service
    module Mail
      module SMTP
        class Config
          
          class << self
            def get
              self.new
            end
          end

          def initialize
          end

        end
      end
    end
  end
end
