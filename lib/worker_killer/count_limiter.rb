module WorkerKiller
  class CountLimiter

    attr_reader :min, :max, :limit, :started_at

    def initialize(min: 3072, max: 4096, verbose: false, &block)
      @min = min
      @max = max
      @limit = @min + WorkerKiller.randomize(@max - @min + 1)
      @left = @limit
      @verbose = verbose
      @reaction = block
    end

    def check
      return nil if @limit <= 1

      @started_at ||= Time.now

      if @verbose
        logger.info "#{self}: worker (pid: #{Process.pid}) has #{@left} left before being limited"
      end

      return false if (@left -= 1) > 0

      logger.warn "#{self}: worker (pid: #{Process.pid}) exceeds max number of requests (limit: #{@limit})"
      @reaction.call(self)

      true
    end

    def logger
      WorkerKiller.configuration.logger
    end

  end
end

