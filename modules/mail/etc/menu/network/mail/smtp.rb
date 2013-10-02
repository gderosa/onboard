# encoding: utf-8

# As you may see,
# the Menu hierarchy and the URL/Ruby classes hierarchy are different!
#
# The former reflects the user's perspective, so Mail goes under Network.
#
# The latter reflects a more technical perspective: everything under
# /network/ may change IP adresses, network interfaces, routing table,
# packet filtering etc...
#
# Instead, /services/ are various daemons/servers operating at the 
# application layer only.

class OnBoard

  MENU_ROOT.add_path('/network/mail/smtp', {
    :href => '/services/mail/smtp',
    :name => 'Outgoing Servers',
    :desc => 'Configure SMTP server(s) to use to send email',
    #:children => %r{/services/mail/smtp/.+$},
    :n    => 0
  })

end

