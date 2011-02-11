class OnBoard
  module ContentFilter
    class DG
      class List

        class << self

          def managed_list_dir
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

          def ls(splat)
            relative_path = splat.join('/') 
            real_path = File.realpath(
                File.join managed_list_dir, relative_path)
            if File.directory? real_path
              ListDir.new real_path
            else
              List.new real_path
            end
          end

        end

        def initialize(path)
          @path = path
        end

      end
    end
  end
end
