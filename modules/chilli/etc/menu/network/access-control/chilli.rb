class OnBoard
  MENU_ROOT.add_path('/network/access-control/chilli', {
    :href     => '/network/access-control/chilli',
    :name     => '&ldquo;Chilli&rdquo; Controller',
    :desc     => 'Redirects unauthenticated users to a login page',
    :n        => 0,
    :children => %r{^/network/access-control/chilli/.*}
  })
end
