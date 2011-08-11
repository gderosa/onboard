# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do
    
      # Following method should be called PROVIDED that the resource exists.
      def format(h)
        h[:formats] ||= %w{html json yaml}
        h[:formats] |= %w{rb} if options.environment == :development

        # try to guess if not provided
        h[:format]                                ||= 
            params[:format]                       ||= 
            request.path_info =~ /\.(\w+$)/ && $1

        return multiple_choices(h) unless h[:formats].include? h[:format]

        if h[:module] 
          h[:path] = '../modules/' + h[:module] + '/views/' + h[:path].sub(/^\//, '') 
        end
        case h[:format]
        when 'html'
          if h[:partial]
            layout = false
          elsif instance_variable_defined? :@layout and @layout
            layout = @layout.to_sym
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

    end
  end
end