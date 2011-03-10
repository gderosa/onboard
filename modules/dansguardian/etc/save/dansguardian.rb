require 'onboard/content-filter/dg'

dg = OnBoard::ContentFilter::DG.new( :bare => true )
dg.get_status
dg.save

