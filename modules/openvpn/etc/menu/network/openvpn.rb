class OnBoard
  MENU_ROOT.add_path('/network/openvpn', {
    :href => '/network/openvpn',
    :children => %r{^/network/openvpn/.*},
    :name => 'OpenVPN',
    :desc => 'Virtual Private Networks',
    :n    => 0
  })
  MENU_ROOT.add_path('/network/openvpn/client-side-configuration', {
    :href => '/network/openvpn/client-side-configuration',
    :children => %r{^/network/openvpn/client-side-configuration/.*},
    :name => 'Client-side configuration Wizard',
    :desc => 'This will also help you to configure Windows clients',
    #:n    => 2
  })
end


