class OnBoard

  MENU_ROOT.add_path('/content-filter', {
    :name => 'Content Filtering',
    :n    => 2
  })

  MENU_ROOT.add_path('/content-filter/dg', {
    #:href => '/content-filter/dansguardian',
    :name => 'DansGuardian',
    :desc => 'DansGuardian Web Content Filtering',
  })

  MENU_ROOT.add_path('/content-filter/dg/main', {
    :href     => '/content-filter/dansguardian',
    :name     => 'Main',
    :n        => 1,
    :children => lambda {|arg| false} 
  })

  MENU_ROOT.add_path('/content-filter/dg/authplugins', {
    :name => 'Authentication',
    :desc => 'Assign users to Filter Groups',
    :n    => 4
  })

  MENU_ROOT.add_path('/content-filter/dg/fg', {
    :href => '/content-filter/dansguardian/filtergroups',
    :name => 'Filter Groups',
    :desc => 
        'You may configure different filtering rules for each group of users',
    :n    => 2
  })

  MENU_ROOT.add_path('/content-filter/dg/lists', {
    :name => 'Lists',
    :n    => 3
  })

  MENU_ROOT.add_path('/content-filter/dg/init', {
    :href => '/content-filter/dansguardian/init',
    :name => 'Reset / Init configuration',
    :n    => 5
  })

end


