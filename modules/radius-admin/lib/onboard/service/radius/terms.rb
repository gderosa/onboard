class OnBoard
  module Service
    module RADIUS
      module Terms
        autoload :Document, 'onboard/service/radius/terms/document'

        class MandatoryDocumentNotAccepted < Conflict; end

      end
    end
  end
end

