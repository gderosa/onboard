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
require 'onboard/extensions/object/deep'
require 'onboard/extensions/sinatra/base'
require 'onboard/menu/node'
require 'onboard/passwd'

class OnBoard
  class Controller < ::Sinatra::Base

    class ArgumentError < ArgumentError; end

    # Extensions must be explicitly registered in modular style apps.
    register ::Sinatra::R18n

    # Several options are not enabled by default if you inherit from 
    # Sinatra::Base .
    enable :methodoverride, :static, :show_exceptions
    
    set :root, OnBoard::ROOTDIR

    # Sinatra::Base#static! has been overwritten to allow multiple path
    set :public, 
        Dir.glob(OnBoard::ROOTDIR + '/public')            +
        Dir.glob(OnBoard::ROOTDIR + '/modules/*/public')      

    set :views, OnBoard::ROOTDIR + '/views'

    case environment
    when :development
      Thread.abort_on_exception = true
      OnBoard::LOGGER.level = Logger::DEBUG
    when :production
      Thread.abort_on_exception = false
      OnBoard::LOGGER.level = Logger::INFO
    end

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

      # Icons and buttons
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
      def action_button(action, *attributes)
        h = attributes[0] || {} 
        raise ArgumentError, "Invalid action: #{action.inspect}" unless 
            [:start, :stop, :config, :reload, :restart].include? action
        type = h[:type] || case action
        when :start, :stop, :reload
          'submit'
        when :config
          'button'
        end
        name = h[:name] || action.to_s 
        value = h[:value] || name
        disabled = h[:disabled] ? 'disabled' : ''
        title = h[:title] || name
        title = title.capitalize 
        alt = h[:alt] || title
        image = case action
                when :start
                  "#{IconDir}/#{IconSize}/actions/media-playback-start.png"
                when :stop
                  "#{IconDir}/#{IconSize}/actions/media-playback-stop.png"
                when :config
                  "#{IconDir}/#{IconSize}/actions/system-run.png"
                when :reload, :restart
                  "#{IconDir}/#{IconSize}/actions/reload.png"
                end
        return %Q{<button type="#{type}" name="#{name}" value="#{value}" #{disabled} title="#{title}"><img src="#{image}" alt="#{alt}"/></button>} 
      end
    
      # Following method should be called PROVIDED that the resource exists.
      def format(h)
        # try to guess if not provided
        h[:format]                                ||= 
            params[:format]                       ||= 
            request.path_info =~ /\.(\w+$)/ && $1

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
            :layout   => layout,
            :locals   => {
              :objects  => h[:objects], 
              :icondir  => IconDir, 
              :iconsize => IconSize,
              :msg      => h[:msg],
              :title    => h[:title],
              :formats  => (h[:formats] || @@formats),
            }.merge(h[:locals] || {}) , 
          )

        when 'json', 'yaml'
          # Some converters use sorts of ASCII escaping, other emit UTF8
          # strings as they are.
          if h[:format] == 'json'
            content_type  'application/json'
          elsif h[:format] == 'yaml' # "explicit is better than implicit" :-)
            if $ya2yaml_available
              content_type 'application/x-yaml', :charset => 'utf-8'
            else
              content_type 'application/x-yaml' # base64(ASCII) used by std lib
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

          return h[:objects].deep_rekey{|k| k.to_s}.to_(h[:format]) 

        when 'rb'
          if options.environment == :development
            content_type 'text/x-ruby'
            return h[:objects].pretty_inspect 
          else
            multiple_choices(h)
          end
        else
          if h[:partial]
            raise ArgumentError, "You requested a partial but you did not provide a valid :format. You may want something like :format => 'html' in #{caller[0]}"
          else
            multiple_choices(h)
          end
        end  
      end

      # much simpler version, no multiple formats here
      def format_file(h)
        if h[:module] 
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '') 
        end
        return erb(
          h[:path].to_sym,
          :layout   => false,
          :locals   => h[:locals] 
        )
      end
     
      def multiple_choices(h={}) 
        status(300)
        paths = []
        formats = h[:formats] || @@formats
        formats.each do |fmt|
          paths << request.path_info.sub(/\.[^\.]*$/, '.' + fmt) 
        end
        formats.each do |fmt|
          args_h = {
            :path     => '300',
            :format   => fmt,
            :formats  => formats
          }
          if request.env["HTTP_ACCEPT"] [fmt] # "contains"
            return format args_h
          end
          format args_h
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
