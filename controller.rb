# encoding: utf-8

require 'rubygems'
require 'thin' # we need to explicit the server, for some reason... :-?
require 'sinatra/base'
require 'sinatra/r18n'
require 'locale'
require 'erb'
require 'find'
require 'json'
require 'yaml'
require 'logger'
require 'pp'

require 'onboard/extensions/object'
require 'onboard/extensions/sinatra/base'
require 'onboard/menu/node'
require 'onboard/passwd'

class OnBoard
  class Controller < ::Sinatra::Base
    # Extensions must be explicitly registered in modular style apps.
    register ::Sinatra::R18n

    # Several options are not enabled by default if you inherit from 
    # Sinatra::Base .
    enable :methodoverride, :static, :show_exceptions
    set :root, OnBoard::ROOTDIR
    set :public, OnBoard::ROOTDIR + '/public'
    set :views, OnBoard::ROOTDIR + '/views'

    Thread.abort_on_exception = true if environment == :development

    use Rack::Auth::Basic do |username, password|
      (File.exists? OnBoard::Passwd::ADMIN_PASSWD_FILE) ?
          (username == 'admin' and Passwd.check_admin_pass password)
      :
          (username == 'admin' and password == 'admin')
    end  

    # TODO: do not hardcode, make it themable :-)
    IconDir = '/icons/gnome/gnome-icon-theme-2.18.0'
    IconSize = '16x16'
    
    include ERB::Util

    @@formats = %w{html json yaml} # order matters
    @@formats << 'rb' if development?

    not_found do
      ## Commented out since it breaks any explicit call to not_found
      ## TODO: find something better
      #
      #if routed? request.path_info, :any 
      #  status(405) # HTTP Method Not Allowed
      #  headers "Allow" => allowed_methods(request.path_info).join(', ')
      #  format(:path=>'405', :format=>'html')
      #else
        status(404)
        format(:path=>'404', :format=>'html') 
      #end
    end

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

      # Icons
      def yes_no_icon(object, *opts)
        if object
          "<img alt=\"#{i18n.yes}\" src=\"#{IconDir}/#{IconSize}/emblems/emblem-default.png\"/>"
        else
          if opts.include? :print_no
            "<span class=\"lowlight\">#{i18n.no}</span>"
          else
            ""
          end
        end
      end
    
      # Following method should be called PROVIDED that the resource exists.
      def format(h)
        if h[:module] 
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '') 
        end
        case h[:format]
        when 'html'
          if h[:partial]
            layout = false
          else
            layout = :"layout.html"
          end
          content_type 'text/html', :charset => 'utf-8'
          return erb(
            (h[:path] + '.html').to_sym,
            :layout => layout,
            :locals => {
              :objects => h[:objects], 
              :icondir => IconDir, 
              :iconsize => IconSize,
              :msg => h[:msg] 
            } 
          )

        when 'json', 'yaml'
          # Some converters use sorts of ASCII escaping, other emit UTF8
          # strings as they are.
          if h[:format] == 'json'
            content_type  'application/json'
          else  # elsif h[:format] == 'yaml' would be redundant...
            if $ya2yaml_1_9compatible_available
              content_type 'application/json', :charset => 'utf-8'
            else
              content_type 'application/json' # base64(ASCII) used by std lib
            end
          end
          # The following is common to YAML and JSON.
          #
          # Let JSON and YAML clients know about error messages via custom hdrs.
          # WARN: X-Err and X-Stderr might be large... ! (TODO?) 
          if h[:msg]
            x_headers = {}
            x_headers['X-Err']    = h[:msg][:err].gsub("\n", "\\n")     if 
                h[:msg][:err]     =~ /\S/
            x_headers['X-Stderr'] = h[:msg][:stderr].gsub("\n", "\\n")  if 
                h[:msg][:stderr]  =~ /\S/
            headers x_headers                                           if 
                x_headers.length > 0
            headers x_headers                                           if 
                x_headers.length > 0
          end
          if h[:objects].class == Array and h[:objects][0].respond_to? :data
            # we assume that array is made up of objects of the same class
            return (h[:objects].map {|obj| obj.data}).to_(h[:format]) 
          elsif h[:objects].respond_to? :data
            return h[:objects].data.to_(h[:format])
          else
            return h[:objects].to_(h[:format])
          end

        when 'rb'
          if options.environment == :development
            content_type 'text/x-ruby'
            return h[:objects].pretty_inspect 
          else
            multiple_choices(h)
          end
        else
          multiple_choices(h)
        end  
      end

      def multiple_choices(h)
        status(300)
        paths = []
        @@formats.each do |fmt|
          paths << request.path_info.sub(/\.[^\.]*$/, '.' + fmt) 
        end
        @@formats.each do |fmt|
          if request.env["HTTP_ACCEPT"] [fmt] # "contains"
            return format(
              :path => '300',
              :format => fmt,
              :objects => {
                :paths => paths, 
              }
            )
          end
          format(
            :path => '300',
            :format => 'html',
            :objects => {
                :paths => paths, 
            }          
          )
        end
      end

    end

    # just to have "CSS variables"
    get '/css/:stylesheet' do
      content_type 'text/css'
      erb ('css/' + params[:stylesheet]).to_sym
    end

    # modular controller
    OnBoard.find_n_load OnBoard::ROOTDIR + '/controller/'

  end

end
