require 'onboard/extensions/string'
require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      module Terms
        class Document

          class << self

            def setup
              @@conf          ||= RADIUS.read_conf
              @@terms_table   ||= @@conf['terms']['table'].to_sym
              @@terms_cols    ||= @@conf['terms']['columns'].symbolize_values
            end

            def setup!
              @@conf = @@terms_table = @@terms_cols = nil
              setup
            end

            def get_all
              setup
              RADIUS.db[@@terms_table].select.map do |row|
                Hash[ 
                  row.map do |k, v| 
                    [
                      k, 
                      v.respond_to?(:smart_encode)  ? 
                          v.smart_encode('utf-8')   : 
                          v
                    ]
                  end
                ]
              end              
            end

            def insert(params)
              setup

              # translate a <select> into two checkboxes :-)
              # (which is why a ReST backend and a web frontend should be separated!) 
              if params['asked required'].respond_to? :include?
                params['asked']     = 'on' if params['asked required'].include? 'asked'
                params['required']  = 'on' if params['asked required'].include? 'required'
              end

              RADIUS.db[@@terms_table].insert( # TODO: generalize column names from conf
                :name     => params['name'],
                :content  => params['content'],
                :asked    => params['asked']    ? true : false,
                :required => params['required'] ? true : false
              )
            end

            def delete(id)
              setup

              # TODO: generalize column names from conf
              RADIUS.db[@@terms_table].filter(:id => id).delete
            end

          end

        end
      end
    end
  end
end

