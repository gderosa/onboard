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
              q = RADIUS.db[@@terms_table].select.map do |row|
                Hash[ 
                  row.map do |k, v| 
                    [
                      k, 
                      v.respond_to?(:force_encoding)  ? 
                          v.force_encoding('iso-8859-1').encode('utf-8')   : 
                          v
                    ]
                  end
                ]
              end
              return q
            end

          end

        end
      end
    end
  end
end

