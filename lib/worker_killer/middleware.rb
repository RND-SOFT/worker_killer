require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class Middleware

    attr_reader :limiter

    def initialize(app, klass:, reaction: nil, **opts)
      @app = app

      reaction ||= proc do |limiter|
        WorkerKiller.kill_self(limiter.logger, limiter.started_at)
      end

      @limiter = klass.new(opts, &reaction)
    end

    def call(env)
      response = @app.call(env)
      @limiter.check
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

