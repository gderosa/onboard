# Registered trademarks belong to their respective owners
# and are cited here solely for testing and illustrative purposes

$LOAD_PATH.unshift File.join File.dirname(__FILE__), '../..'

require 'onboard/hardware/lsusb' 

include OnBoard::Hardware

# lsusb | grep -v 'Device 001' | grep -v '0000:0000' # exclude root hubs
sample_output = <<END
Bus 001 Device 008: ID 0951:1642 Kingston Technology DT101 G2
Bus 001 Device 009: ID 1a40:0101 Terminus Technology Inc. 4-Port HUB
END

describe LSUSB, '.parse' do
  it %q{should give two objects} do
    LSUSB.parse(sample_output).length.should be = 2
  end
end

devices = LSUSB.parse(sample_output)
kingst, exthub = devices

describe LSUSB, '#bus_id' do
  it %q{should get Bus ID} do
    kingst.bus_id.should be == '001'
    exthub.bus_id.should be == '001'
  end
end

describe LSUSB, '#device_id' do
  it %q{should get Device ID} do
    kingst.device_id.should be == '008'
    exthub.device_id.should be == '009'
  end
end

describe LSUSB, '#vendor_id' do
  it %q{should get Vendor ID} do
    kingst.vendor_id.should be == '0951'
    exthub.vendor_id.should be == '1a40'
  end
end

describe LSUSB, '#product_id' do
  it %q{should get Product ID} do
    kingst.product_id.should be == '1642'
    exthub.product_id.should be == '0101'
  end
end
 
