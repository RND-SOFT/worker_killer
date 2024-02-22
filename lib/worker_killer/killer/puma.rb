module ::WorkerKiller
  module Killer
    class Puma < ::WorkerKiller::Killer::Base

      def initialize **kwrags
        super
      end

      def do_kill(sig, pid, alive_sec, **_params)
        cmd = 'pumactl phased-restart'

        if sig == :KILL
          logger.error "#{self} force to kill self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
          return
        end

        return if @already_detached

        logger.warn "#{self} run #{cmd.inspect} (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
        @already_detached = true

        Thread.new(cmd) do |command|
          unless Kernel.system(command)
            logger.warn "#{self} run #{command.inspect} failed: #{$?.inspect}"
          end
        end
      end

    end
  end
end

