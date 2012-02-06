# encoding: UTF-8

class OnBoard
  class Controller < ::Sinatra::Base
    helpers do

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
              :delete,
              :pause,
              :start_paused, 
            ].include? action 
        type = h[:type] || case action
        when :start, :stop, :restart, :reload, :delete, :pause, :start_paused
          'submit'
        when :config
          'button'
        end
        name = h[:name] || action.to_s 
        value = h[:value] || name
        disabled = h[:disabled] ? 'disabled' : ''
        title = h[:title] || name.capitalize
        alt = h[:alt] || title
        image = case action
                when :start
                  "#{IconDir}/#{IconSize}/actions/media-playback-start.png"
                when :stop
                  "#{IconDir}/#{IconSize}/actions/media-playback-stop.png"
                when :pause
                  "#{IconDir}/#{IconSize}/actions/media-playback-pause.png"
                when :start_paused # used by qemu module...
                  "#{IconDir}/#{IconSize}/actions/media-skip-forward.png"
                when :config
                  "#{IconDir}/#{IconSize}/actions/system-run.png"
                when :reload, :restart
                  "#{IconDir}/#{IconSize}/actions/reload.png"
                when :delete
                  "#{IconDir}/#{IconSize}/actions/delete.png"
                end
        return %Q{<button type="#{type}" name="#{name}" value="#{value}" #{disabled} title="#{title}"><img src="#{image}" alt="#{alt}"/></button>} 
      end

      def mandatory_mark
        '<span style="font-weight:bold; color:red">*</span>'
      end

    end
  end
end
