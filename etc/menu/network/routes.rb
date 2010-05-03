class OnBoard

  MENU_ROOT.add_path('/network/routing', {
    :name => 'Routing',
    :n    => -10
  })
  
  MENU_ROOT.add_path('/network/routing/basic', {
    :href => '/network/routing/tables/main',
    :name => 'Basic / main table',
    :desc => 'Main table',
    :n    => -10
  })

  MENU_ROOT.add_path('/network/routing/advanced', {
    :name => 'Advanced / Policy Routing'
  })

  MENU_ROOT.add_path('/network/routing/advanced/multiple-tables', {
    :href => '/network/routing/tables',
    :name => 'Multiple tables'
  })

end
