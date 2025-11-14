module WorkerKiller
  module Killer
    class DelayedJob < ::WorkerKiller::Killer::Base

      def do_kill(sig, pid, alive_sec, dj:, **_kwargs)
        case sig
        when :QUIT
          logger.info "#{self.class}: try to stop DelayedJob due to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (kill attempts #{kill_attempts})"
          dj.stop
        when :TERM
          logger.warn "#{self.class}: force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (kill attempts #{kill_attempts})"
          Process.kill sig, pid
        when :KILL
          logger.error "#{self.class}: force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (kill attempts #{kill_attempts})"
          Process.kill sig, pid
        else
          logger.error "#{self.class}: DO NOTHING: unknown #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (kill attempts #{kill_attempts})"
        end
      end

    end
  end
end

