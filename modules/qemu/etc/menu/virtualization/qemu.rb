class OnBoard

  MENU_ROOT.add_path('/virtualization', {
    :name => 'Virtualization',
    :n    => 0
  })
 
  MENU_ROOT.add_path('/virtualization/qemu', {
    :name => 'QEMU / kvm',
    :href => '/virtualization/qemu',
    :n    => 0
  })

end
