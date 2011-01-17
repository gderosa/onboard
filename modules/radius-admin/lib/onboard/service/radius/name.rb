# encoding: utf-8

class OnBoard
  module Service
    module RADIUS
      module Name

        class InvalidCharacters < BadRequest; end

        class << self

          def validate(name)
            unless name =~ /^[a-z0-9\-_:]+$/iu
              raise InvalidCharacters, %Q{Name #{name.inspect} contains invalid characters.\nOnly use A-Z, a-z, 0-9, '-', '_', ':'. Do not use accented and/or non-English characters.}
            end
          end

        end

      end
    end
  end
end
