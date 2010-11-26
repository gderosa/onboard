class OnBoard
  module Network
    module AAA
      # AAA::RADIUS goes under Network because it's all about an 
      # Internet Standard, just like QoS::DSCP ...
      #
      # Instead Service::RADIUS, defined elsewhere, gives methods to 
      # edit users database or view accounting data.
      module RADIUS
        ROOTDIR = File.dirname(__FILE__)
        DICTIONARYDIR = "#{ROOTDIR}/data"
        $LOAD_PATH.unshift  ROOTDIR + '/lib'
      end
    end
  end
end

