require 'onboard/extensions/string'
require 'onboard/extensions/hash'

class OnBoard
  module Service
    module RADIUS
      module Terms
        class Document
          # TODO TODO TODO: generalize column names from conf

          class << self

            def setup
              @@conf                ||= RADIUS.read_conf
              @@terms_table         ||= @@conf['terms']['table'].to_sym
              @@terms_accept_table  ||= @@conf['terms_accept']['table'].to_sym
              @@terms_cols          ||= @@conf['terms']['columns'].symbolize_values
            end

            def setup!
              @@conf = @@terms_table = @@terms_cols = nil
              setup
            end

            def get_all(filter_={})
              setup
              q = RADIUS.db[@@terms_table].filter(filter_)

              hashes = q.map do |row|
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

              hashes.each do |h| # TODO: a smart join...
                h[:accept_count] = RADIUS.db[@@terms_accept_table].filter(:terms_id => h[:id]).count
              end

              return hashes
            end

            def get(id, options={})
              default_options = {:content => true}
              options         = default_options.merge options
              setup
              table           = RADIUS.db[@@terms_table]
              columns         = options[:content] ?
                table.columns                     :
                table.columns - [:content]          # unused?
              document        = table.select(*columns)[:id => id]
              return unless document
              Hash[
                document.map do |k, v|
                  [
                    k,
                    v.respond_to?(:smart_encode)  ?
                       v.smart_encode('utf-8')    :
                       v
                  ]
                end
              ]
            end

            def insert(params)
              setup
              wrap_params! params

              RADIUS.db[@@terms_table].insert(
                :name     => params['name'],
                :content  => params['content'],
                :asked    => params['asked']    ? true : false,
                :required => params['required'] ? true : false
              )
            end

            def update(id, params)
              setup
              wrap_params! params

              RADIUS.db[@@terms_table].filter(:id => id).update(
                :name     => params['name'],
                :content  => params['content'],
                :asked    => params['asked']    ? true : false,
                :required => params['required'] ? true : false
              )

              get(id)
            end

            def delete(id)
              setup

              RADIUS.db[@@terms_table].filter(:id => id).delete
            end

            private

            def wrap_params(params); wrap_params!(params.dup); end

            def wrap_params!(params)
              # translate a <select> into two checkboxes :-)
              # (which is why a ReST backend and a web frontend should be separated!)
              if params['asked required'].respond_to? :include?
                params['asked']     = 'on' if params['asked required'].include? 'asked'
                params['required']  = 'on' if params['asked required'].include? 'required'
              end
              params
            end

          end

        end
      end
    end
  end
end

