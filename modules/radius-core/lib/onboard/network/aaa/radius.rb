require 'radiustar' # custom fork

class OnBoard
  module Network
    module AAA
      module RADIUS
        class << self
          def dictionary(which_dictionary)  
            file = case which_dictionary
                   when Symbol 
                     "#{DATADIR}/dictionary.#{which_dictionary}"
                   else # String ...
                     which_dictionary # file
                   end
            Radiustar::Dictionary.new( file ) 
          end
        end
      end
    end
  end
end
