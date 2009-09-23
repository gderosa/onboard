class OnBoard
  module Network
    class WiFi < Interface
      def initialize(h)
        @underlying_phyisical = h[:underlying_physical].name
        # @ip_carrying = h[:ip_carrying].name # it's itself!
        @ip = h[:ip_carrying].ip
        @name = h[:ip_carrying].name
        @type = 'wi-fi'
        @ipassign = h[:ip_carrying].ipassign
        @mac = h[:ip_carrying].mac       
        @mtu = h[:ip_carrying].mtu       
        @vendor = h[:ip_carrying].vendor 
        @model = h[:ip_carrying].model  
        @state = h[:ip_carrying].state 
        @active = h[:ip_carrying].active 
        # Maybe this is not necessary?
        #if @state == 'UP' and (
        #    @underlying_physical.misc.include? 'NO-CARRIER' or
        #    @ip_carrying.misc.include? 'NO-CARRIER'
        #)
        #  @state = 'NO-CARRIER'
        #end
      end
    end
  end
end
