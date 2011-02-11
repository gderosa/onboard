class OnBoard
  module ContentFilter
    class DG
      class ManagedList

        class << self

          def root_dir
            "#{CONFDIR}/lists/_managed"
          end

          def title(splat)
            input   = {:adjective => splat[0],  :noun => splat[1] }
            output  = input.clone
            if    input[:noun]  ==  'extensions'
              output[:noun]       =   'file extensions'
            elsif input[:noun]  == 'MIMEtypes'
              output[:noun]       =   'MIME types'
            end
            return "#{output[:adjective]} #{output[:noun]}"
          end

          def ls(relative_path)
            real_path = File.realpath(
                File.join root_dir, relative_path
            ) 
            if File.directory? real_path
              ManagedListDir.new :relative_path => relative_path
            else
              ManagedList.new    :relative_path => relative_path
            end
          end

        end

        def initialize(h)
          @relative_path = h[:relative_path]
        end

      end
    end
  end
end
