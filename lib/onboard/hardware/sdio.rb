require 'onboard/constants'
# The above also fixes an issue when chain-loaded from openvpn --up script
# (modules/openvpn/etc/scripts/up)
# and possibly other places.

class OnBoard
  module Hardware
    module SDIO

      DATAFILE = File.join(OnBoard::ROOTDIR, 'share/hardware/sdio.ids')

      class << self

        def vendormodel_from_ids(vendor_id, model_id)
          vendor = nil
          model = nil
          File.readlines(DATAFILE).each do |line|
            line.sub! /\s+#.*$/, ''
            if vendor
              if line =~ /^\s+#{model_id}\s+(.*)/i
                model = $1.strip
              end
            else
              if line =~ /^#{vendor_id}\s+(.*)/i
                vendor = $1.strip
              end
            end
          end
          return vendor, model
        end

      end

    end
  end
end
