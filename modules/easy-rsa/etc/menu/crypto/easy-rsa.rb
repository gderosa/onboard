class OnBoard
  MENU_ROOT.add_path('/crypto', {
    :name => 'Cryptography',
    :n    => 3
  })
end

class OnBoard
  MENU_ROOT.add_path('/crypto/easy-rsa', {
    :href => '/crypto/easy-rsa',
    :name => 'Manage PKIs',
    #:desc => 'Public Key Infrastructures and own Certificate Authorities',
    :n    => 2
  })
end
