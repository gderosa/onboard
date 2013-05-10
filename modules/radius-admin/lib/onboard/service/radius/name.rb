# encoding: utf-8

class OnBoard
  module Service
    module RADIUS
      module Name

        VALID_CHARACTERS_HUMAN_READABLE_LIST = %q{A-Z, a-z, 0-9, '-', '_', ':'}

        class InvalidCharacters < BadRequest; end

        class << self

          def validate(name, opts={})
            i18n = opts[:i18n]
            unless name =~ /^[a-z0-9\-_:]+$/iu
              if i18n
                raise InvalidCharacters, %Q{#{i18n.name.weak_article(1).capitalize} #{name.inspect} #{i18n.contains_invalid_chars(1)}.\n#{i18n.use_only.all.capitalize} #{VALID_CHARACTERS_HUMAN_READABLE_LIST}. #{i18n.do_not_use_accented_chars.capitalize}. }
              else
                raise InvalidCharacters, %Q{Name #{name.inspect} contains invalid characters.\nOnly use A-Z, a-z, 0-9, '-', '_', ':'. Do not use accented and/or non-English characters.}
              end
            end
          end

        end

      end
    end
  end
end
