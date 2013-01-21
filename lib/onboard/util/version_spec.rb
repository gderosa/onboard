$LOAD_PATH.unshift File.join File.dirname(__FILE__), '../..'

require 'onboard/util/version' 

include OnBoard::Util

describe Version, '#<=>' do
  it %q{should be Version.new('1.2.3') < '1.3'} do
    Version.new('1.2.3').should be < '1.3'
  end
  it %q{should be Version[1, 2, 3] < '1.3'} do
    Version[1, 2, 3].should be < '1.3'
  end
  it %q{should be '1.3' > Version.new('1.2.3')} do
    '1.3'.should be > Version.new('1.2.3')
  end
  it %q{should be '1.3' > Version[1, 2, 3]} do
    '1.3'.should be > Version[1, 2, 3]
  end
end

