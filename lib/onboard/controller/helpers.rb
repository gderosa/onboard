# encoding: UTF-8

require 'rubygems'
require 'thin' 
require 'rack/utils'
require 'sinatra/base'
require 'sinatra/r18n'
require 'locale'
require 'erubis'
require 'find'
require 'json'
require 'yaml'
require 'logger'

require 'onboard/extensions/object'
require 'onboard/extensions/object/deep'
require 'onboard/extensions/sinatra/base'
require 'onboard/menu/node'
require 'onboard/passwd'
require 'onboard/pagination'

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
            [
              :start, 
              :stop, 
              :config, 
              :reload, 
              :restart, 
              :delete
            ].include? action 
        type = h[:type] || case action
        when :start, :stop, :reload, :delete
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
                when :delete
                  "#{IconDir}/#{IconSize}/actions/delete.png"
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
          return erubis(
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
            err                   = h[:msg][:err].to_s
            stderr                = h[:msg][:stderr].to_s
            x_headers['X-Err']    = err.gsub("\n", "\\n")     if err    =~ /\S/
            x_headers['X-Stderr'] = stderr.gsub("\n", "\\n")  if stderr =~ /\S/
            headers x_headers                                            
          end

          return h[:objects].to_(h[:format]) 

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

      def partial(h)
        format(
          h.update(
            :format   => 'html',
            :partial  => true
          )
        )
      end

      def paginator(h)
        partial(
          :path     => '_paginator',
          :locals   => h
        )
      end

      def message_partial(msg={:ok=>true}) 
        erubis(
          :"/_messages.html",
          {
            :layout => false,
            :locals => {
              :msg => msg,
              :status => status
            }
          }
        )
      end

      # much simpler version, no multiple formats here
      def format_file(h)
        if h[:module] 
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '') 
        end
        return erubis(
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

      def handle_external_errors(e, req)
        result = nil
        @@error_handlers ||= {}
        exception_handlers = @@error_handlers[e.class] || []  
        exception_handlers.each do |handler|
          result = handler.call(e, req)
          return result if result and result != :pass 
        end
        return result
      end

      def handle_errors(&blk)
        msg = {}
        begin
          blk.call
        rescue OnBoard::Error
          e = $!.clone
          status e.http_status_code
          msg[:err] = e # will be converted to message string as needed
        rescue OnBoard::Warning
          msg[:warn] = $!
        rescue StandardError
          if h = handle_external_errors($!, request) 
            status h[:status]
            msg = h[:msg]
          else
            raise # unhandled
          end
        end
        msg[:ok] = true unless msg[:err]
        return msg
      end

      def use_pagination_defaults()
        params.update OnBoard::Pagination.normalize(params) 
      end

      def parent_path
        "#{File.dirname(request.path_info)}.#{params[:format]}"
      end

      def query_string_merge(h)
        # Rack::Request#GET doesn't play well when :method_ovverride
        # is enabled in Sinatra. 
        get_params = Rack::Utils.parse_query(request.query_string)
        Rack::Utils.build_query(
          get_params.merge(h) 
        )
      end

      # backward-compatibility for code based on ERB::Util
      def url_encode(str)
        Rack::Utils.escape(str) 
      end

      def current_encoding
        response['Content-Type'] =~ /charset\s*=\s*([^\s;,]+)/
        encname = $1.dup
        begin
          Encoding.find encname
        rescue ArgumentError
          Encoding.find 'utf-8'
        end
      end

      def main_menu
        OnBoard::MENU_ROOT.to_html_ul do |node, output|
          if node.content

            # if a "children rule" is not specified, create it (if possible)
            if node.content[:href] and not node.content[:children]
              node.content[:children] = /^#{node.content[:href].to_dir}/
            end

            if request.path_info ==  node.content[:href]
              output[:href] = nil
              output[:extra_class] = "hmenu-selected"
            # That's why I love Ruby: node.content[:children] may
            # be a String, a Regexp or even a block of code! (lambda)
            elsif node.content[:children] === request.path_info
              output[:extra_class] = "hmenu-selected" unless
                  # do not highlight if any descendant matches already
                  node.any? do |n|
                    n.content[:href]      ==  request.path_info or
                    n.content[:children]  === request.path_info and
                    n                     !=  node # exclude itself
                  end
            end
          end
        end
      end

    end
  end
end
