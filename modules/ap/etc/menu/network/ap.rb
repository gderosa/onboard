class OnBoard
  MENU_ROOT.add_path('/network/ap', {
    :href     => '/network/ap',
    :name     => 'Wireless Access Point',
    #:desc     => 'Redirects unauthenticated users to a login page',
    :n        => 0,
    :children => %r{^/network/ap/.*}
  })
end
