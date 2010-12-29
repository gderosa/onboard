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

  MENU_ROOT.add_path('/network/access-control/radius', {
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

  MENU_ROOT.add_path('/network/access-control/radius/users', {
    :href     => '/services/radius/users',
    :name     => 'Users',
    :children => %r{/services/radius/users/.+$},
    :n        => 30
  })

  MENU_ROOT.add_path('/network/access-control/radius/groups', {
    :href     => '/services/radius/groups',
    :name     => 'Groups',
    :children => %r{/services/radius/groups/.+$},
    :n        => 40
  })

  MENU_ROOT.add_path('/network/access-control/radius/resetdb', {
    :href     => '/services/radius/resetdb',
    :name     => 'Reset Database',
    :n        => 50
  })

end

