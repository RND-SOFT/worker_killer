require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class Middleware

    attr_reader :limiter, :killer, :reaction

    def initialize(app, killer:, klass:, reaction: nil, **opts)
      @app = app
      @killer = killer

      @reaction = reaction || proc do |l, k|
        k.kill(l.started_at)
      end

      @limiter = klass.new(opts)
    end

    def call(env)
      response = @app.call(env)
      reaction.call(limiter, killer) if limiter.check
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

