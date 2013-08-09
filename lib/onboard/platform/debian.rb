require 'fileutils'

class OnBoard
  module Platform
    module Debian # with fallback if no /etc/init.d/ ...
      def self.restart_dnsmasq(confdir)
        msg = OnBoard::System::Command.run(
            '/etc/init.d/dnsmasq stop', :sudo, :try)
        if not msg[:ok] 
          msg = OnBoard::System::Command.run(
              'killall dnsmasq', :sudo, :try)
        elsif not msg[:ok]
          msg = OnBoard::System::Command.run(
            'killall -9 dnsmasq', :sudo, :try)
        end
        # 'new' subdirectory is always the current config dir
        # do not copy new/*.conf to parent directory if you don't want
        # persistence        
        msg = OnBoard::System::Command.run(
            'DNSMASQ_OPTS="--conf-dir=' << 
            confdir << '" ' <<
            '/etc/init.d/dnsmasq start', 
            :sudo, :try
        )
        if not msg[:ok]
          msg = OnBoard::System::Command.run(
              "dnsmasq --conf-dir=#{confdir}", 
              :sudo
          )
        end   
      end
    end
  end
end
