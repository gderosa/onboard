class OnBoard
  MENU_ROOT.add_path('/network/openvpn', {
    :href => '/network/openvpn',
    :children => %r{^/network/openvpn/vpn/.+},
    :name => 'OpenVPN',
    :desc => 'Virtual Private Networks',
    :n    => 2
  })
end
