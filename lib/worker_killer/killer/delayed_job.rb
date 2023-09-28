module WorkerKiller
  module Killer
    class DelayedJob < ::WorkerKiller::Killer::Base

      def do_kill(sig, pid, alive_sec, dj:, **_params)
        if sig == :KILL
          logger.error "#{self.class}: force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
          return
        end

        dj.stop
        logger.info "#{self.class}: try to stop DelayedJob due to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"

        return if sig != :TERM

        if @termination
          logger.warn "#{self.class}: force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
        else
          @termination = true
        end
      end

    end
  end
end

