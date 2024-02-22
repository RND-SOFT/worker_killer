require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'
require 'puma/plugin'

Puma::Plugin.create do

module WorkerKiller
  class PumaPlugin

    attr_reader :limiter, :killer, :reaction

    def initialize(klass:, killer:, reaction: nil, **opts)
      @killer = killer

      @reaction = reaction || proc do |l, k, dj|
        k.kill(l.started_at, dj: dj)
      end

      @limiter = klass.new(**opts)
      @time_to_burn = false
    end

    def new(lifecycle = Delayed::Worker.lifecycle, *_args)
      configure_lifecycle(lifecycle)
    end

    def configure_lifecycle(lifecycle)
      # Count condition after every job
      lifecycle.after(:perform) do |worker, *_args|
        @time_to_burn ||= limiter.check
      end
      
      # Stop execution only after whole loop completed
      lifecycle.after(:loop) do |worker, *_args|
        @time_to_burn ||= limiter.check
        reaction.call(limiter, killer, worker) if @time_to_burn
      end
    end

    class JobsLimiter < ::WorkerKiller::PumaPlugin

      def initialize(**opts)
        super(klass: ::WorkerKiller::CountLimiter, **opts)
      end

    end

    class OOMLimiter < ::WorkerKiller::PumaPlugin

      def initialize(**opts)
        super(klass: ::WorkerKiller::MemoryLimiter, **opts)
      end

    end

  end
end

