require 'dansguardian'

class OnBoard
  module ContentFilter
    class DG
      class FilterGroup

        class << self
          def get(id)
            new(
              :id => id.to_i
            )
          end
        end
          
        def initialize(h)
          @id   = h[:id]
          @file = DG.fg_file(@id)
        end

        def fgdata
          @fgdata ||= ::DansGuardian::Config.new(
            :mainfile => ::OnBoard::ContentFilter::DG.config_file
          ).filtergroup(@id)
          @fgdata
        end

        def export
          h = {}
          fgdata.data.each_pair do |k, v|
            k = k.to_s # Symbol#to_s! does not exist :-)
            if k =~ /list$/
              if v =~ /^#{DG::ManagedList.root_dir}\/(.*)/
                repath = $1
                h[k] = repath
              end
            else
              h[k] = v
            end
          end
          return h
        end

        def to_json(*a); export.to_json(*a); end
        def to_yaml(*a); export.to_yaml(*a); end

        def update!(params)
          # Update Hash: will be the argument of
          # ::DansGuardian::Updater.update!
          u = {} 
          u['groupname']        = params['groupname']
          u['naughtynesslimit'] = params['naughtynesslimit']
          u['groupmode'] =  
              ::DansGuardian::Config::FilterGroup::GROUPMODE.invert[ 
                  params['groupmode'].to_sym 
              ]
          u['disablecontentscan'] = case params['enablecontentscan']
                                    when 'on'
                                      'off'
                                    else
                                      'on'
                                    end
          u['blockdownloads'] = case params['blockdownloads']
                                    when 'on'
                                      'on'
                                    else
                                      'off'
                                    end
          u['weightedphrasemode'] = case params['weightedphrasemode']
                                    when ''
                                      :remove!
                                    else
                                      params['weightedphrasemode']
                                    end
          params.each_pair do |key, value|
            if key =~ /list$/
              u[key] = DG::ManagedList.absolute_path value
            end
          end

          ::DansGuardian::Updater.update!(@file, u)
        end

      end
    end
  end
end
