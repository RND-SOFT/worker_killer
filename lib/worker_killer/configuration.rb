require 'logger'

module WorkerKiller
  # Methods for configuring WorkerKiller
  class Configuration

    attr_accessor :logger, :quit_attempts, :kill_attempts, :use_quit

    # Override defaults for configuration
    def initialize(quit_attempts: 5, kill_attempts: 10, use_quit: true)
      @quit_attempts = quit_attempts
      @kill_attempts = kill_attempts
      @use_quit = use_quit
      @logger = Logger.new(STDOUT, level: Logger::INFO, progname: 'WorkerKiller')
    end

  end
end

