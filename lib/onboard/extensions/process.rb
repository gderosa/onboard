module Process
  class << self
    # http://stackoverflow.com/a/3568291
    def running?(pid)
      begin
        Process.getpgid( pid )
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end
