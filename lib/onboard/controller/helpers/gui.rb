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

      def drive_icon(drive, *attributes)
        defaults = {:img => true}
        h     = defaults.update( attributes[0] || {} ) 
        title = h[:title]     || h['name']  || ''
        alt   = title         || ''
        image = case drive.to_sym
                when :hard_disk, :hard_drive, :hd, :disk
                  "#{IconDir}/#{IconSize}/devices/drive-harddisk.png"     
                when :optical, :cdrom, :cd, :dvd, :blueray
                  "#{IconDir}/#{IconSize}/devices/drive-optical.png"
                else
                  raise ArgumentError, "Invalid drive category: #{drive}"
                end
        if h[:img]
          return %Q{<img class="drive" src="#{image}"/>} 
        else
          return image
        end
      end

      def action_button(action, *attributes)
        h = attributes[0] || {} 
        raise ArgumentError, "Invalid action: #{action.inspect}" unless 
            [
              :start, 
              :stop, 
              :process_stop,
              :shutdown,
              :config, 
              :reload, 
              :restart, 
              :delete,
              :pause,
              :start_paused, 
            ].include? action 
        type = h[:type] || case action
        when :config
          'button'
        else 
          'submit'
        end
        name = h[:name] || action.to_s 
        value = h[:value] || name
        disabled = h[:disabled] ? 'disabled' : ''
        title_str =  h[:title] || name.capitalize
        alt = h[:alt] || title_str
        title = (!h[:disabled] or h[:title_always]) ? title_str : ''
        image = case action
                when :start
                  "#{IconDir}/#{IconSize}/actions/media-playback-start.png"
                when :stop
                  "#{IconDir}/#{IconSize}/actions/media-playback-stop.png"
                when :process_stop
                  "#{IconDir}/#{IconSize}/actions/process-stop.png"
                when :shutdown
                  "#{IconDir}/#{IconSize}/actions/shutdown.png"
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
