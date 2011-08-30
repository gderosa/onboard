# encoding: UTF-8

gem 'locale'
autoload :Locale, 'locale'

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      # Localization helpers 
      def locale
        if params['locale']
          Locale::Tag.parse(params['locale'])
        elsif session['locale']
          Locale::Tag.parse(session['locale'])
        elsif Kernel.const_defined? :R18n
          Locale::Tag.parse(i18n.locale.code)
        end          
      end
      def syslocale; Locale.current; end
      def current_language_code; locale.language; end
      def current_country_code
        locale.country or
        Locale::Tag.parse(i18n.locale.code).country or
        syslocale.country or
        'US'
      end
      def countries
        # I18nData.countries is slow, at least reading from CF cards,
        # so a basic cache mechanism is implemented.
        @@countries = {} unless 
            self.class.class_variable_defined? :@@countries
        @@countries[current_language_code] = 
            I18nData.countries current_language_code unless 
                @@countries[current_language_code]
       @@countries[current_language_code]
      end
      def country_codes_by_name
        countries.keys.sort_by {|x| countries[x]}
      end

    end
  end
end
