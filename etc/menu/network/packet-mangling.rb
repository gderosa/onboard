class OnBoard
  # to the average user, the internet is IPv4, and the firewall too :-(
  MENU_ROOT.add_path('/network/packet-mangling', {
    :name => 'Packet mangling (advanced)',
    :desc => 'Do not change these settings if you\'re not sure!',
    :n    => 0
  })
end
