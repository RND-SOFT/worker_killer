require 'get_process_mem'

module WorkerKiller
  class MemoryLimiter

    attr_reader :min, :max, :limit, :started_at, :check_cycle

    def initialize(min: (1024**3), max: (2 * (1024**3)), check_cycle: 16, verbose: false)
      @min = min
      @max = max
      @limit = @min + WorkerKiller.randomize(@max - @min + 1)
      @check_cycle = check_cycle
      @check_count = 0
      @verbose = verbose
    end

    def check
      return nil if @limit <= 1024**2

      @started_at ||= Time.now
      @check_count += 1

      return nil if (@check_count % @check_cycle) != 0

      rss = GetProcessMem.new.bytes
      if @verbose
        logger.info "#{self.class}: worker (pid: #{Process.pid}) using #{rss} bytes(#{rss / 1024 / 1024}mb)."
      end
      @check_count = 0

      return false if rss <= @limit

      logger.warn "#{self.class}: worker (pid: #{Process.pid}) exceeds memory limit (#{rss} bytes > #{@limit} bytes)"

      true
    end

    def logger
      WorkerKiller.configuration.logger
    end

  end
end

