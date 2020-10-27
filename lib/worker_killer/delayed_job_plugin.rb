require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
    class DelayedJobPlugin < ::Delayed::Plugin

      attr_reader :limiter, :dj

      def initialize(klass:, killer:, reaction: nil, **opts)

        reaction ||= proc do |l, k, d|
          k.kill(l.started_at)
        end

        @limiter = klass.new(opts) do |limiter|
          reaction.call(limiter, killer, dj)
        end
      end

      def new *args
        configure_lifecycle(Delayed::Worker.lifecycle)
      end

      def configure_lifecycle |lifecycle|
        lifecycle.before(:execute) do |worker, *args|
          @dj ||= worker
          killer.dj = dj
        end

        lifecycle.after(:perform) do |worker, *args|
          limiter.check
        end

      end

    end
end

