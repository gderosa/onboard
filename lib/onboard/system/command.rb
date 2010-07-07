require 'logger'
require 'open3'

class OnBoard

  LOGGER ||= Logger.new(STDERR)

  module System
    module Command

      class RuntimeError < ::RuntimeError; end

      DEFAULT_LOG_LEVEL = :debug

      def self.bgexec(cmd, *opts)
        msg = {:background => true}
        if opts.include? :sudo and ::Process.uid != 0
          if opts.include? :keepenv
            cmd_do = 'sudo -E ' + cmd
          else
            cmd_do = 'sudo ' + cmd
          end
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
          if opts.include? :keepenv
            cmd_do = 'sudo -E ' + cmd
          else
            cmd_do = 'sudo ' + cmd
          end
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
          error_as = :error
          errmsg = "Command failed: \"#{cmd_do}\" (#{wait_thr.value})"
          if opts.include? :try
            error_as  = DEFAULT_LOG_LEVEL
            errmsg = "Attempt failed: \"#{cmd_do}\" (#{wait_thr.value})"
          end
          LOGGER.method(error_as).call(errmsg)
          msg[:err] = errmsg unless opts.include?(:try)
          msg[:stderr].each_line do |line|
            line.strip!
            LOGGER.method(error_as).call line if line =~ /\S/
          end
          msg[:stdout].each_line do |line|
            line.strip!
            LOGGER.info line if line =~ /\S/
          end
        else
          LOGGER.method(DEFAULT_LOG_LEVEL).call "Command success: \"#{cmd_do}\""
        end
        stdin.close
        stdout.close
        stderr.close
        if !msg[:ok] and !opts.include?(:try) and opts.include?(:raise_exception)
          raise RuntimeError, msg[:err]
        end
        return msg
      end

      # TODO? backtick equivalent still unimplemented, maybe we won't need it?

    end
  end
end

