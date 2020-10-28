require 'logger'

module WorkerKiller
  # Methods for configuring WorkerKiller
  class Configuration

    attr_accessor :logger, :quit_attempts, :term_attempts

    # Override defaults for configuration
    def initialize(quit_attempts: 10, term_attempts: 50)
      @quit_attempts = quit_attempts
      @term_attempts = term_attempts
      @logger = Logger.new(STDOUT, level: Logger::INFO, progname: 'WorkerKiller')
    end

  end
end

