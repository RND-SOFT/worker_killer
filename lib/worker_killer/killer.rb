module WorkerKiller
  module Killer
    class Base

      attr_accessor :config, :kill_attempts, :logger

      def initialize(logger: WorkerKiller.configuration.logger, **_kwargs)
        @logger = logger
        @config = WorkerKiller.configuration
        @kill_attempts = 0
      end

      def kill(start_time)
        alive_sec = (Time.now - start_time).round

        @kill_attempts += 1

        sig = :QUIT
        if config.use_quit
          sig = :TERM if kill_attempts > config.quit_attempts
          sig = :KILL if kill_attempts > (config.quit_attempts + config.term_attempts)
        else
          sig = :TERM
          sig = :KILL if kill_attempts > config.term_attempts
        end

        do_kill(sig, Process.pid, alive_sec)
      end

      def do_kill *_args
        raise 'Not Implemented'
      end

    end
  end
end

require_relative 'killer/signal'
require_relative 'killer/passenger'
require_relative 'killer/delayed_job'

