require 'sequel'
require 'sequel/extensions/pagination'

class OnBoard
  module Service
    module RADIUS
      module Accounting

        class << self
        
          def get(params)
            page      = params[:page].to_i
            per_page  = params[:per_page].to_i
            select    = RADIUS.db[:radacct].select(
              :Radacctid, :Username, 
              :Nasipaddress, :Nasporttype, 
              :Acctstarttime, :Acctstoptime, :Acctsessiontime,
              :Acctinputoctets, :Acctoutputoctets,
              :Calledstationid, :Callingstationid,
              :Acctterminatecause,
              :Framedipaddress
            )
            {
              'rows'        => select.paginate(page, per_page).to_a,
              'total_items' => select.count,
              'page'        => page,
              'per_page'    => per_page
            }
          end

        end

      end
    end
  end
end 
