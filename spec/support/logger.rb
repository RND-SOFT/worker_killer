RSpec.configure do |config|
  config.before(:suite) do
    $logger = Logger.new(STDOUT).tap do |logger|
      logger.progname = "WorkerKille"
      logger.level = "ERROR"
    end
    WorkerKiller.configure do |cfg|
      cfg.logger = $logger
    end
  end
end

