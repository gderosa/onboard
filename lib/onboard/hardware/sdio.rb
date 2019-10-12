class OnBoard
  module Hardware
    module SDIO

      DATAFILE = File.join(OnBoard::ROOTDIR, 'share/hardware/sdio.ids')

      class << self
        def vendormodel_from_ids(vendor_id, model_id)
          File.readlines(DATAFILE).each do |line|
            next if line =~ /^\s*#/
            puts line
          end
        end
      end

    end
  end
end
