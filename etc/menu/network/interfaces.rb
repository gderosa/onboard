class OnBoard
  MENU_ROOT.add_path('/network/interfaces', {
    :href     => '/network/interfaces',
    :children => /\/network\/interfaces\/.+/,
    :name     => 'Interfaces',
    :desc     => 'Network interfaces',
    #:n        => -10
  })
end
