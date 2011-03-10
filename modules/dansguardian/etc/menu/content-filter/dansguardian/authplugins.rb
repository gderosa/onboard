class OnBoard

  MENU_ROOT.add_path('/content-filter/dg/authplugins/sql', {
    :name => 'SQL/RADIUS',
    :desc => 'Captive Portal and 802.1X integration',
  })

  MENU_ROOT.add_path('/content-filter/dg/authplugins/sql/groups', {
    :name => 'Group Mapping',
    :href => '/content-filter/dansguardian/authplugins/sql/groups',
    :n    => 1
  })
  MENU_ROOT.add_path('/content-filter/dg/authplugins/sql/db', {
    :name => 'Database and queries',
    :href => '/content-filter/dansguardian/authplugins/sql/db',
    :n    => 2
  })

end


