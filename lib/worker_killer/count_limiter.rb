module WorkerKiller
  class CountLimiter

    attr_reader :min, :max, :left, :limit, :started_at

    def initialize(min: 3072, max: 4096, verbose: false)
      @min = min
      @max = max
      @limit = nil
      @left = nil

      @started_at = Time.now
      @triggered = false
      @verbose = verbose
    end

    def initialize_limits
      @limit = min + WorkerKiller.randomize(max - min + 1)
      @left = @limit
    end

    def check
      return true if @triggered

      initialize_limits if @limit.nil?

      return nil if @limit < 1

      if @verbose
        logger.info "#{self.class}: worker (pid: #{Process.pid}) has #{@left} left before being limited"
      end

      return false if (@left -= 1) > 0

      @triggered = true
      logger.warn "#{self.class}: worker (pid: #{Process.pid}) exceeds max number of requests (limit: #{@limit})"
      true
    end

    def logger
      WorkerKiller.configuration.logger
    end

  end
end

