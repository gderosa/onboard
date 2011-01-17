class OnBoard
  MENU_ROOT.add_path('/network/bridges', {
    :href => '/network/bridges',
    :children => /\/network\/bridges\/.+/,
    :name => 'Bridges',
    :desc => 'A bridge is a group of network interfaces which act as one, sharing IP addresses etc.',
    :n    => 0
  })
end
