class OnBoard
  MENU_ROOT.add_path('/webif', {
    :name => 'Web Interface',
    :desc => '',
    :n    => 9 
  })
  #MENU_ROOT.add_path('/webif/admin', {
  #  :name => 'Administrators',
  #  :desc => '',
  #  :n    => 10
  #})
  MENU_ROOT.add_path('/webif/pub', {
    :name => 'Public interface / End users',
    :desc => 'for example, signup/selfcare pages for endusers, hotspot etc.',
    :n    => 20
  })
end


