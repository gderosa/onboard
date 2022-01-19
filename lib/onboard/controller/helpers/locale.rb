# encoding: UTF-8

require 'locale'
require 'sinatra/r18n'

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      # Localization helpers

      # Turn localized dates into something Date.parse could understand
      def r18n_normalize_date(str)
        case r18n.locale.code
        when /en.us/i
          mm, dd, yyyy = str.split('/')
          "#{yyyy}-#{mm}-#{dd}" # also "#{dd}/#{mm}/#{yyyy}" would have been good
        else
          str
        end
      end

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
