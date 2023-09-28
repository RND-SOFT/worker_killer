module WorkerKiller
  module Killer
    class Base

      attr_accessor :config, :kill_attempts, :logger

      def initialize(logger: nil, **_kwargs)
        @logger = logger
        @config = WorkerKiller.configuration
        @kill_attempts = 0
      end

      def kill(start_time, **params)
        alive_sec = (Time.now - start_time).round

        @kill_attempts += 1

        sig = :QUIT
        sig = :TERM if kill_attempts > config.quit_attempts
        sig = :KILL if kill_attempts > (config.quit_attempts + config.term_attempts)

        do_kill(sig, Process.pid, alive_sec, **params)
      end

      # :nocov:
      def do_kill(*_args)
        raise 'Not Implemented'
      end
      # :nocov:
      
      def logger
        @logger || WorkerKiller.configuration.logger
      end

    end
  end
end

require_relative 'killer/signal'
require_relative 'killer/passenger'
require_relative 'killer/delayed_job'

