class OnBoard

  MENU_ROOT.add_path('/virtualization', {
    :name => 'Virtualization',
    :n    => 0
  })

  MENU_ROOT.add_path('/virtualization/qemu', {
    :name => 'QEMU / kvm',
    :desc => 'Manage QEMU Virtual Machines',
    :href => '/virtualization/qemu',
    :n    => 0
  })

  MENU_ROOT.add_path('/virtualization/qemu/common', {
    :name => 'Common Settings',
    :href => '/virtualization/qemu/common',
    :n    => 0
  })

end
