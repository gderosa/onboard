require 'timeout'

require 'onboard/virtualization/qemu'

SHUTDOWN_TIMEOUT      = 420 
QUICK_SAVEVM_TIMEOUT  = 120

OnBoard::Virtualization::QEMU.get_all.each do |vm|
  next if vm.running?
  print "\n  Shutting down VM '#{vm.name}'... "
  STDOUT.flush
  if vm.quick_snapshots?
    begin
      Timeout.timeout(QUICK_SAVEVM_TIMEOUT) do
        vm.savevm_quit
      end
    rescue Timeout::Error
      vm.quit
    end
  else
    begin
      Timeout.timeout(SHUTDOWN_TIMEOUT) do
        while(vm.running?)
          vm.acpi_powerdown
          sleep 4
        end
      end
    rescue Timeout::Error
      vm.quit
    end
  end
end


