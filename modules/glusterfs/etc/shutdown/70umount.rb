require 'onboard/system/command'

Dir.glob "#{OnBoard::FILESDIR}/*network*/gluster/*/*" do |dir|
  OnBoard::System::Command.run "umount '#{dir}'", :sudo
end
