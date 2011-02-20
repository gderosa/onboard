require 'dansguardian'

class OnBoard
  module ContentFilter
    class DG
      class FilterGroup

        class << self
          def get(id)
            new(
              :id => id
            )
          end
        end
          
        def initialize(h)
          @id   = h[:id]
          @file = DG.fg_file(@id)
        end

        def update!(params)
          pp params
          
          # Update Hash: will be the argument for ::DansGuardian::Updater.update!
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
