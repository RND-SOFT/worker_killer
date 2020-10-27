require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class DelayedJobPlugin

    attr_reader :limiter, :dj

    def initialize(klass:, killer:, reaction: nil, **opts)
      reaction ||= proc do |l, k, _d|
        k.kill(l.started_at)
      end

      @limiter = klass.new(opts) do |limiter|
        reaction.call(limiter, killer, dj)
      end
    end

    def new(*_args)
      configure_lifecycle(Delayed::Worker.lifecycle)
    end

    def configure_lifecycle lifecycle
      lifecycle.before(:execute) do |worker, *_args|
        @dj ||= worker
        killer.dj = dj
      end

      lifecycle.after(:perform) do |_worker, *_args|
        limiter.check
      end
    end

  end
end

