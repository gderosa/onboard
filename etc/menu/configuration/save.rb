class OnBoard
  MENU_ROOT.add_path('/configuration/save', {
    :href => '/configuration/save',
    :name => 'Save',
    :desc => 'Save the current configuration so it will not be lost at the next reboot',
    :n    => 10
  })
end
