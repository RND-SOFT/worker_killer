module WorkerKiller
  module Killer
    class DelayedJob < ::WorkerKiller::Killer::Base

      def do_kill(sig, pid, alive_sec, dj:, **_params)
        if sig == :KILL
          logger.error "#{self} force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
          return
        end

        dj.stop

        return if sig != :TERM

        if @termination
          logger.warn "#{self} force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
        else
          @termination = true
        end
      end

    end
  end
end

