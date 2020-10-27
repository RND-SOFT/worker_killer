require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class Middleware

    attr_reader :limiter, :killer

    def initialize(app, killer:, klass:, reaction: nil, **opts)
      @app = app
      @killer = killer

      reaction ||= proc do |l, k|
        k.kill(l.started_at)
      end

      @limiter = klass.new(opts) do |limiter|
        reaction.call(limiter, killer)
      end
    end

    def call(env)
      response = @app.call(env)
      limiter.check
      response
    end

    class RequestsLimiter < ::WorkerKiller::Middleware

      def initialize(app, **opts)
        super(app, klass: ::WorkerKiller::CountLimiter, **opts)
      end

    end

    class OOMLimiter < ::WorkerKiller::Middleware

      def initialize(app, **opts)
        super(app, klass: ::WorkerKiller::MemoryLimiter, **opts)
      end

    end

  end
end

