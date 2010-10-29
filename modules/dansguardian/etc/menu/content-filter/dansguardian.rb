class OnBoard
  MENU_ROOT.add_path('/content-filter', {
    :name => 'Content Filtering',
    :n    => 2
  })
  MENU_ROOT.add_path('/content-filter/dg', {
    :href => '/content-filter/dansguardian',
    :name => 'DansGuardian',
    :desc => 'DansGuardian Web Content Filtering',
  })
end


