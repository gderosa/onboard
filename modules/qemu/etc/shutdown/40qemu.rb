require 'timeout'

require 'onboard/virtualization/qemu'

SHUTDOWN_TIMEOUT      = 420 
QUICK_SAVEVM_TIMEOUT  = 120

running_VMs = OnBoard::Virtualization::QEMU.get_all.select{|vm| vm.running?}

puts if running_VMs.any?

running_VMs.each do |vm|
  next unless vm.running?
  if vm.quick_snapshots?
    print "  Saving state of VM '#{vm.name}'... "
    STDOUT.flush
    begin
      Timeout.timeout(QUICK_SAVEVM_TIMEOUT) do
        vm.savevm_quit
        puts 'OK'
      end
    rescue Timeout::Error
      puts $!.class
      vm.quit
    end
  else
    print "  Shutting down VM '#{vm.name}'... "
    STDOUT.flush
    begin
      Timeout.timeout(SHUTDOWN_TIMEOUT) do
        while(vm.running?)
          vm.acpi_powerdown
          sleep 4
        end
      end
    rescue Timeout::Error
      puts $!.class
      vm.quit
    end
  end
end




