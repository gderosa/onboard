# encoding: UTF-8

require 'sinatra/base'

require 'onboard/extensions/sinatra/base'
require 'onboard/extensions/sinatra/templates'

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

      # Following method should be called PROVIDED that the resource exists.
      def format(h)

        h[:msg] ||= msg

        #h[:formats] ||= %w{html json yaml}
        #h[:formats] |= %w{rb} if settings.environment == :development
        h[:formats] = @@formats

        # try to guess if not provided
        h[:format]                                ||=
            params[:format]                       ||=
            request.path_info =~ /\.(\w+$)/ && $1

        return multiple_choices(h) unless h[:formats].include? h[:format]
        # h[:path] and abs_path are with no extension!
        if h[:module]
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '')
        end
        abs_path = File.absolute_path( File.join(settings.views, h[:path]) )
        case h[:format]
        when 'html'
          if h[:partial]
            layout = false
          elsif instance_variable_defined? :@layout and @layout
            layout = @layout.to_sym
                # a mobile layout is set in lib/onboard/controller/auth.rb
                # (if appropriate) only for /pub/ pages right now
          else
            layout = :"layout.html" # TODO? mobile layout for admin (non /pub/ ) pages?
          end

          content_type 'text/html', :charset => 'utf-8' unless h[:partial]

          erubis_template = (h[:path] + '.html').to_sym
          # p abs_path + '.mobi.html.erubis' if abs_path =~ /_form_style/ # DEBUG
          if File.exists?( abs_path + '.mobi.html.erubis' ) and mobile?
            erubis_template = (h[:path] + '.mobi.html').to_sym
            # p erubis_template if abs_path =~ /_form_style/ # DEBUG
          end

          # "Sinatra::Templates#erubis is deprecated and will be removed,
          # use #erb instead. If you have Erubis installed, it will be used
          # automatically"
          return erb(
            erubis_template,
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
            content_type 'application/x-yaml', :charset => 'utf-8'
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

          if h[:msg][:ok] == false 
            return h[:msg].to_(h[:format])
          else
            return h[:objects].to_(h[:format])
          end

        when 'rb' # development check already done
          #if options.environment == :development
            content_type 'text/x-ruby'
            return h[:objects].pretty_inspect
          #else
          #  multiple_choices(h)
          #end
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

      def message_partial(h={})
        @msg ||= {}
        @msg.merge! (h or {:ok => true}) 
        partial(
          :path => '_messages', 
          :locals => {
            :msg => @msg,
            :status => status
          }
        )
      end

      # much simpler version, no multiple formats here
      def format_file(h)
        if h[:module] 
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '') 
        end
        return erb( # See above for #erb Vs #erubis
          h[:path].to_sym,
          :layout   => false,
          :locals   => h[:locals] 
        )
      end

    end
  end
end
