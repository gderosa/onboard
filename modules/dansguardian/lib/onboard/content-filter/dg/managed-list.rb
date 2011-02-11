class OnBoard
  module ContentFilter
    class DG
      module ManagedList

        autoload :Dir,  'onboard/content-filter/dg/managed-list/dir'
        autoload :List, 'onboard/content-filter/dg/managed-list/list'       

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
            if splat.length > 2
              subpath = splat[2..-1].join('/')
              return "#{output[:adjective]} #{output[:noun]}: #{subpath}"
            else
              return "#{output[:adjective]} #{output[:noun]}"
            end
          end

          def get(relative_path)
            real_path = File.realpath(
                File.join root_dir, relative_path
            ) 
            if File.directory? real_path
              ManagedList::Dir.new  :relative_path => relative_path
            else
              ManagedList::List.new :relative_path => relative_path
            end
          end

        end

      end
    end
  end
end
