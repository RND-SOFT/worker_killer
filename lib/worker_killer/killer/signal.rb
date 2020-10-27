module WorkerKiller
  module Killer
    class Signal < ::WorkerKiller::Killer::Base

      def do_kill(sig, pid, alive_sec)
        return if sig == @last_signal

        @last_signal = sig
        logger.warn "#{self} send SIG#{sig} (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
        Process.kill sig, pid
      end

    end
  end
end
