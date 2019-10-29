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
          begin
            stdout.each_line do |line|
              LOGGER.info line.strip
            end
          rescue IOError
          end
        end
        Thread.new do
          # very basic heuristic to interpret stderr output as warning or error
          begin
            stderr.each_line do |line|
              level = :warn
              level = :error if line =~ /err(orr|[^a-z])/i
              LOGGER.method(level).call line.strip
            end
          rescue IOError
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
        at_exit {
          if wait_thr.alive?
            print "Waiting for #{wait_thr}: #{cmd} ..."
            wait_thr.join and puts 'OK'
          end
        }
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
          errmsg = "Command failed: #{cmd_do} # (#{wait_thr.value})"
          if opts.include? :try
            error_as  = DEFAULT_LOG_LEVEL
            errmsg = "Attempt failed: #{cmd_do} # (#{wait_thr.value})"
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
          LOGGER.method(DEFAULT_LOG_LEVEL).call "Command success: #{cmd_do}"
        end
        stdin.close
        stdout.close
        stderr.close
        if !msg[:ok] and !opts.include?(:try)
          if opts.include?(:raise_exception)
            raise RuntimeError, msg[:err]
          elsif opts.include?(:raise_Conflict)
            raise Conflict, msg[:err] + "\n" + msg[:stderr]
          elsif opts.include?(:raise_BadRequest)
            raise BadRequest, msg[:err] + "\n" + msg[:stderr]
          end
        end
        return msg
      end

      # Only use exception, not message passing
      def self.send_command(cmd, *opts)
        opt_h = opts.find{|opt| opt.is_a? Hash} || {}
        if opt_h[:sudo] or opts.include? :sudo
          if opt_h[:keepenv] or opts.include? :keepenv
            cmd = 'sudo -E '  + cmd
          else
            cmd = 'sudo '     + cmd
          end
        end
        stdout, stderr, status = Open3.capture3(
          cmd,
          :stdin_data => opt_h[:stdin]
        )
        stdout.strip!
        stderr.strip!
        if status.success?
          LOGGER.debug  "Command success: #{cmd}"
          LOGGER.debug  stdout unless stdout.empty?
          LOGGER.warn   stderr unless stderr.empty?
        else
          LOGGER.error  "Command failed: #{cmd}"
          LOGGER.error  stderr unless stderr.empty?
          LOGGER.info   stdout unless stdout.empty?
          raise opt_h[:raise], stderr if opt_h[:raise]
        end
      end

      # TODO? backtick equivalent still unimplemented, maybe we won't need it?

    end
  end
end

