require 'fileutils'

class OnBoard
  ROOTDIR ||= File.expand_path(
    File.join File.dirname(__FILE__), '../../..'
  )
  module Platform
    module Debian # with fallback if no /etc/init.d/ ...

      # Use a modified init script.
      #
      # Currently, this is to get rid of --local-service, which
      # doesn't seem to play very well with virtualization and
      # TAP bridges.
      #
      DNSMASQ_INIT_SCRIPT =
          "#{::OnBoard::ROOTDIR}/etc/scripts/platform/debian/init.d/dnsmasq"

      def self.restart_dnsmasq(confdir)
        msg = OnBoard::System::Command.run(
            "#{DNSMASQ_INIT_SCRIPT} stop", :sudo, :try)
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
            "#{DNSMASQ_INIT_SCRIPT} start",
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
