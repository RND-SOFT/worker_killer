require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class Middleware

    attr_reader :limiter, :killer, :reaction, :inhibitions

    # inhibitions - список адресов, которые будут времнно блокировать перезапуск воркеров:
    # Rails.application.config.middleware.insert_before(
    #   Rack::Sendfile,
    #   WorkerKiller::Middleware::RequestsLimiter, killer:, min: 2, max: 3, inhibitions: ['/test']
    # )
    #
    def initialize(app, killer:, klass:, inhibitions: [], reaction: nil, **opts)
      @app = app
      @killer = killer

      @inhibitions = if @killer.respond_to?(:do_inhibit)
        inhibitions.dup.freeze
      else
        [].freeze
      end

      @reaction = reaction || method(:default_kill)

      @limiter = klass.new(**opts)
    end

    def call(env)
      inhibited = false
      if (path_info = env['PATH_INFO']) && inhibitions.any?{|i| path_info[i] }
        inihibit(path_info)
        inhibited = true
      end

      tuple = @app.call(env)
      tuple = with_inhibition(tuple) if inhibited

      tuple
    ensure
      reaction.call(limiter, killer) if killer && limiter.check
    end

    def with_inhibition(tuple)
      # Почему именно each описано в спецификации в разделе The Response
      # https://github.com/rack/rack/blob/main/SPEC.rdoc
      if tuple[2].respond_to?(:each)
        old = tuple[2]
        tuple[2] = Enumerator.new do |y|
          old.each do |chunk|
            y << chunk
          end
          old.close if old.respond_to?(:close)
          release
        end
      else
        release
      end
      tuple
    end

    def default_kill(l, k)
      k.kill(l.started_at)
    end

    def inihibit(path_info)
      killer.do_inhibit(path_info)
    rescue StandardError => e
      logger.error "#{self.class}::inhibit error: #{e.inspect}"
    end

    def release
      killer.do_release
    rescue StandardError => e
      logger.error "#{self.class}::release error: #{e.inspect}"
    end

    def logger
      @logger ||= WorkerKiller.configuration.logger
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

