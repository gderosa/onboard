class OnBoard

  MENU_ROOT.add_path('/content-filter/dg/lists/banned', {
    :name => 'Black lists',
    :n    => 1
  })

  MENU_ROOT.add_path('/content-filter/dg/lists/banned/sites', {
    :href => '/content-filter/dansguardian/lists/banned/sites',
    :name => 'Sites',
    :n    => 1
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/banned/URLs', {
    :href => '/content-filter/dansguardian/lists/banned/URLs',
    :name => 'URLs',
    :n    => 2
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/banned/phrases', {
    :href => '/content-filter/dansguardian/lists/banned/phrases',
    :name => 'Phrases',
    :n    => 3
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/banned/extensions', {
    :href => '/content-filter/dansguardian/lists/banned/extensions',
    :name => 'File extensions',
    :n    => 4
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/banned/MIMEtypes', {
    :href => '/content-filter/dansguardian/lists/banned/MIMEtypes',
    :name => 'MIME types',
    :n    => 5
  })

  MENU_ROOT.add_path('/content-filter/dg/lists/exception', {
    :name => 'White lists',
    :n    => 2
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/exception/sites', {
    :href => '/content-filter/dansguardian/lists/exception/sites',
    :name => 'Sites',
    :n    => 1
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/exception/URLs', {
    :href => '/content-filter/dansguardian/lists/exception/URLs',
    :name => 'URLs',
    :n    => 2
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/exception/phrases', {
    :href => '/content-filter/dansguardian/lists/exception/phrases',
    :name => 'Phrases',
    :n    => 3
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/exception/extensions', {
    :href => '/content-filter/dansguardian/lists/exception/extensions',
    :name => 'File extensions',
    :n    => 4
  })
  MENU_ROOT.add_path('/content-filter/dg/lists/exception/MIMEtypes', {
    :href => '/content-filter/dansguardian/lists/exception/MIMEtypes',
    :name => 'MIME types',
    :n    => 5
  })

  MENU_ROOT.add_path('/content-filter/dg/lists/weightedphrases', {
    :href => '/content-filter/dansguardian/lists/weighted/phrases',
    :name => 'Weighted phrases',
    :n    => 3
  })

end


