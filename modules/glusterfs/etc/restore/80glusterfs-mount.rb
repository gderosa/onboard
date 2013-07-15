require 'onboard/system/command'

# glusterd might not be started because network saw unconfigured
# TODO: should be moved under Platform/Debian or such
OnBoard::System::Command.run "/etc/init.d/glusterfs-server start", :sudo

Dir.glob "#{OnBoard::FILESDIR}/*network*/gluster/*/*" do |dir|
  if dir =~ %r{([^/]+)/([^/]+)$}
    host, volume = $1, $2
    OnBoard::System::Command.run "mount -t glusterfs #{host}:/#{volume} '#{dir}'", :sudo
  end
end
