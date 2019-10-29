require 'onboard/controller/auth'

class OnBoard
  if Controller.public_pages?
    MENU_ROOT.add_path('/webif', {
      :name => 'Web Interface',
      :desc => '',
      :n    => 9
    })
    MENU_ROOT.add_path('/webif/pub', {
      :name => 'Public interface / End users',
      :desc => 'for example, signup/selfcare pages for endusers, hotspot etc.',
      :n    => 20
    })
    MENU_ROOT.add_path('/webif/pub/layout', {
      :href => '/webif/pub/layout',
      :name => 'Layout',
      :desc => 'Logo and custom text',
    })
  end
end
