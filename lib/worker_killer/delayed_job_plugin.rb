require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class DelayedJobPlugin

    attr_reader :limiter, :killer, :reaction

    def initialize(klass:, killer:, reaction: nil, **opts)
      @killer = killer

      @reaction = reaction || proc do |l, k, dj|
        k.kill(l.started_at, dj: dj)
      end

      @limiter = klass.new(opts)
    end

    def new(*_args)
      configure_lifecycle(Delayed::Worker.lifecycle)
    end

    def configure_lifecycle(lifecycle)
      lifecycle.after(:perform) do |worker, *_args|
        reaction.call(limiter, killer, worker) if limiter.check
      end
    end

    class JobsLimiter < ::WorkerKiller::DelayedJobPlugin

      def initialize(**opts)
        super(klass: ::WorkerKiller::CountLimiter, **opts)
      end

    end

    class OOMLimiter < ::WorkerKiller::DelayedJobPlugin

      def initialize(**opts)
        super(klass: ::WorkerKiller::MemoryLimiter, **opts)
      end

    end

  end
end

