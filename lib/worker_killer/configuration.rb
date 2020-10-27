require 'logger'

module WorkerKiller
  # Methods for configuring WorkerKiller
  class Configuration

    attr_accessor :logger, :quit_attempts, :term_attempts, :use_quit, :passenger_config

    # Override defaults for configuration
    def initialize(quit_attempts: 5, term_attempts: 10, use_quit: true, passenger_config: nil)
      @quit_attempts = quit_attempts
      @term_attempts = term_attempts
      @use_quit = use_quit
      @passenger_config = check_passenger(passenger_config)
      @logger = Logger.new(STDOUT, level: Logger::INFO, progname: 'WorkerKiller')
    end

    def passenger?
      !@passenger_config.nil?
    end

    def check_passenger(provided_path)
      if provided_path.nil? || provided_path.empty?
        check_passenger_config(`which passenger-config`)
      else
        check_passenger_config!(provided_path)
      end
    end

    def check_passenger_config path
      path.strip!
      help = `#{path} detach-process --help 2> /dev/null`
      return path if help['Remove an application process from the Phusion Passenger process pool']
    rescue StandardError => e
      nil
    end

    def check_passenger_config! path
      if path = check_passenger_config(path)
        path
      else
        raise "Can't find passenger config at #{path.inspect}"
      end
    end

  end
end

