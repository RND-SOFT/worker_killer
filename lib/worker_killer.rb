require 'worker_killer/configuration'
require 'worker_killer/count_limiter'
require 'worker_killer/memory_limiter'
require 'worker_killer/middleware'

module WorkerKiller

  class << self

    attr_accessor :configuration

  end

  def self.configure
    self.configuration ||= WorkerKiller::Configuration.new
    yield(configuration) if block_given?
  end

  self.configure

  def self.randomize(integer)
    RUBY_VERSION > '1.9' ? Random.rand(integer.abs) : rand(integer)
  end

  # Kill the current process by telling it to send signals to itself. If
  # the process isn't killed after `configuration.quit_attempts` QUIT signals,
  # send TERM signals until `configuration.kill_attempts`. Finally, send a KILL
  # signal. A single signal is sent per request.
  def self.kill_self(logger, start_time)
    alive_sec = (Time.now - start_time).round
    self_pid = Process.pid

    @kill_attempts ||= 0
    @kill_attempts += 1

    if configuration.use_quit
      sig = :QUIT
      sig = :TERM if @kill_attempts > configuration.quit_attempts
    else
      sig = :TERM
    end

    sig = :KILL if @kill_attempts > configuration.kill_attempts

    logger.warn "#{self} send SIG#{sig} (pid: #{self_pid}) alive: #{alive_sec} sec (trial #{@kill_attempts})"
    Process.kill sig, self_pid
  end

end

