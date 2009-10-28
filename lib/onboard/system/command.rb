require 'logger'
require 'open3'

class OnBoard
  module System
    module Command

      def self.bgexec(cmd, *opts)
        msg = {:background => true}
        if opts.include? :sudo and ::Process.uid != 0
            cmd_do = 'sudo ' + cmd
        else
          cmd_do = cmd
        end
        LOGGER.info "Executing \"#{cmd}\" in background..."
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd_do)
        Thread.new do
          stdout.each_line do |line|
            LOGGER.info line.strip
          end
        end
        Thread.new do
          # very basic heuristic to interpret stderr output as warning or error
          stderr.each_line do |line|
            level = :warn
            level = :error if line =~ /err(orr|[^a-z])/i
            LOGGER.method(level).call line.strip
          end
        end
        Thread.new do
          if wait_thr.value != 0
            LOGGER.error "Command \"#{cmd}\" failed (#{wait_thr.value})"
          end
          stdin.close
          stdout.close
          stderr.close 
        end
        return msg
      end

      def self.run(cmd, *opts)
        if opts.include? :sudo and ::Process.uid != 0
            cmd_do = 'sudo ' + cmd
        else
          cmd_do = cmd
        end
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd_do)
        msg = {
          :ok     => true,
          :cmd    => cmd,
          :status => 0,
          :stdout => stdout.read,
          :stderr => stderr.read
        }
        if wait_thr.value != 0
          msg[:ok] = false
          msg[:status] = wait_thr.value.exitstatus
          # if we know how to safely handle an error, treat errors as 
          # something smaller
          error_as = (opts.include?(:try) ? :warn : :error)
          LOGGER.method(error_as).call(
            "Command \"#{cmd}\" failed (#{wait_thr.value})")
          msg[:stderr].each_line do |line|
            line.strip!
            LOGGER.method(error_as).call line if line =~ /\S/
          end
          msg[:stdout].each_line do |line|
            line.strip!
            LOGGER.info line if line =~ /\S/
          end
        end
        stdin.close
        stdout.close
        stderr.close
        return msg
      end

      # TODO? backtick equivalent still unimplemented, maybe we won't need it?

    end
  end
end

