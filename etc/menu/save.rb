class OnBoard
  MENU_ROOT.add_path('/save', {
    :href => '/save',
    :name => 'Save configuration',
    :desc => 'Save the current configuration so it will not be lost at the next reboot',
    :n    => 10
  })
end
