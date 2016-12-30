class OnBoard
  MENU_ROOT.add_path('/network/access-control', {
    :name => 'Access Control',
    :desc => 'Captive Portal, RADIUS, etc.)',
    #:n    => 0 # default
  })
  MENU_ROOT.add_path('/network/access-control/expert', {
    :name => 'Advanced',
    :n => 99
  })
end
