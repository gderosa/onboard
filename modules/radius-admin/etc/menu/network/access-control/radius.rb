# encoding: utf-8

# As you may see,
# the Menu hierarchy and the URL/Ruby classes hierarchy are different!
#
# The former reflects the user's perspective, so CoovaChilli, hotspotlogin,
# and RADIUS server management will fall under the same category.
#
# The latter reflects a more technical perspective: everything under
# /network/ may change IP adresses, network interfaces, routing table,
# packet filtering etc...
#
# Instead, /services/ are various daemons/servers operating at the
# application layer only.

class OnBoard

  MENU_ROOT.add_path('/network/access-control', {
    #:href => '/services/radius', # nil
    :name => 'Access Control',
    #:desc => 'Authentication, Authorization and Accounting',
    #:children => %r{/services/radius/.+$},
    :n    => 0
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius', {
    #:href => '/services/radius', # nil
    :name => 'RADIUS server',
    :desc => 'Authentication, Authorization and Accounting',
    :children => %r{/services/radius/.+$},
    :n    => 0
  })

  MENU_ROOT.add_path('/network/access-control/radius/config', {
    :href => '/services/radius/config',
    :name => 'Configuration',
    :n    => 10
  })

  MENU_ROOT.add_path('/network/access-control/radius/accounting', {
    :href => '/services/radius/accounting',
    :name => 'Accounting',
    :desc => 'Track users consumption of network resources',
    :n    => 20
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/users', {
    :href     => '/services/radius/users',
    :name     => 'Users',
    :children => %r{/services/radius/users/.+$},
    :n        => 30
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/groups', {
    :href     => '/services/radius/groups',
    :name     => 'Groups',
    :children => %r{/services/radius/groups/.+$},
    :n        => 40
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/endusers', {
    :name     => 'End users',
    :n        => 50,
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/endusers/signup', {
    :href     => '/services/radius/signup',
    :name     => 'Signup and Selfcare',
    :desc     => 'End users may create new accounts or edit their own details',
    :n        => 40
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/endusers/terms', {
    :href     => '/services/radius/terms',
    :name     => '&ldquo;Terms and Conditions&rdquo;',
    :desc     => 'Usage policies, Privacy and other regulation documents',
    :n        => 50
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/endusers/password-recovery', {
    :href     => '/services/radius/password-recovery',
    :name     => 'Password Recovery',
    :n        => 60
  })

  MENU_ROOT.add_path('/network/access-control/expert/radius/resetdb', {
    :href     => '/services/radius/resetdb',
    :name     => 'Reset Database',
    :n        => 60
  })

end

