require 'logger'

module WorkerKiller
  # Methods for configuring WorkerKiller
  class Configuration

    # Attempts configuration is deprecated and unsed
    attr_accessor :logger, :quit_attempts, :term_attempts

    # Override defaults for configuration
    # Attempts configuration is deprecated and unsed
    def initialize(quit_attempts: 10, term_attempts: 50)
      # Attempts configuration is deprecated and unsed
      @quit_attempts = quit_attempts
      @term_attempts = term_attempts
      @logger = Logger.new(STDOUT, level: Logger::INFO, progname: 'WorkerKiller')
    end

  end
end

