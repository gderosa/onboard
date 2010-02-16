class OnBoard
  # to the average user, the internet is IPv4, and the firewall too :-(
  MENU_ROOT.add_path('/network/firewall', {
    :href => '/network/firewall/ipv4',
    :name => 'Firewall',
    :desc => 'Filter Internet traffic (IPv4)',
    :n    => 0
  })
end
