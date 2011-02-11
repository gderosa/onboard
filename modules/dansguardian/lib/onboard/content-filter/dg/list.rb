class OnBoard
  module ContentFilter
    class DG
      class List
        class << self
          def title(splat)
            input   = {:adjective => splat[0],  :noun => splat[1] }
            output  = input.clone
            if    input[:noun]  ==  'extensions'
              output[:noun]       =   'file extensions'
            elsif input[:noun]  == 'MIMEtypes'
              output[:noun]       =   'MIME types'
            end
            return "#{output[:adjective]} #{output[:noun]}"
          end
        end
      end
    end
  end
end
