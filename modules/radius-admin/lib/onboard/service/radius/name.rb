# encoding: utf-8

class OnBoard
  module Service
    module RADIUS
      module Name

        class InvalidCharacters < BadRequest; end

        class << self

          def validate(name)
            unless name =~ /^[a-z0-9-_:]+$/iu
              raise InvalidCharacters, %Q{Name "#{name}" contains invalid characters} 
            end
          end

        end

      end
    end
  end
end
