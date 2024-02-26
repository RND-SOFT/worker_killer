require 'get_process_mem'

module WorkerKiller
  class MemoryLimiter

    attr_reader :min, :max, :limit, :started_at, :check_cycle

    def initialize(min:, max:, check_cycle: 16, verbose: false)
      if min
        # set static memory limits
        @min = min
        @max = max
      else
        # prepare for relative memory limits
        @max_percent = max
      end

      @check_cycle = check_cycle
      @check_count = 0
      @verbose = verbose
    end

    def check
      @started_at ||= Time.now
      @check_count += 1


      return nil if (@check_count % @check_cycle) != 0

      rss = GetProcessMem.new.bytes

      # initialize relative memory limits on first check
      if @limit.nil?
        if min.nil?
          set_limits(rss, rss + rss * @max_percent)
        else
          set_limits(min, min + WorkerKiller.randomize(max - min + 1))
        end
      end

      do_check(rss)
    end

    def do_check(rss)
      rss_mb = (rss / 1024 / 1024).round(1)

      if @verbose
        logger.info "#{self.class}: worker (pid: #{Process.pid}) using #{rss_mb} MB (of #{@limit_mb} MB)"
      end
      @check_count = 0

      return false if rss <= @limit

      logger.warn "#{self.class}: worker (pid: #{Process.pid}) exceeds memory limit (#{rss_mb} MB > #{@limit_mb} MB)"

      true
    end

    def set_limits(min, max)
      @min = min
      @limit = max
      @max ||= max
      @limit_mb = (@limit / 1024 / 1024).round(1)
    end

    def logger
      WorkerKiller.configuration.logger
    end

  end
end

