class OnBoard
  MENU_ROOT.add_path('/network/dns', {
    :href => '/network/dns',
    :name => 'DNS',
    :desc => 'DNS forwarder',
    :n    => 0
  })

  MENU_ROOT.add_path('/network/dns/domains', {
    :href => '/network/dns/domains',
    :name => 'Domains',
    :desc => 'Block domains, define domain mail servers etc.'#,
    #:n    => -3
  })
end
