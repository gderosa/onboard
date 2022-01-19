class OnBoard
  MENU_ROOT.add_path('/network/routing', {
    :name => 'Routing',
    #:n    => -10
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
    :href     => '/network/routing/tables',
    :children => lambda do |uri_path|
      uri_path =~ %r{^/network/routing/tables/.+} and not
      uri_path =~ %r{^/network/routing/tables/main\.\w+$}
    end,
    :name     => 'Tables'
  })

  MENU_ROOT.add_path('/network/routing/advanced/rules', {
    :href => '/network/routing/rules',
    :name => 'Rules'
  })

end
