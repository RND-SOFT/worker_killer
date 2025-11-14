require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class Middleware

    attr_reader :limiter, :killer, :interval, :reaction, :inhibitions

    # inhibitions - список адресов, которые будут времнно блокировать перезапуск воркеров:
    # Rails.application.config.middleware.insert_before(
    #   Rack::Sendfile,
    #   WorkerKiller::Middleware::RequestsLimiter, killer:, min: 2, max: 3, inhibitions: ['/test']
    # )
    #
    def initialize(app, killer:, klass:, interval: 10, inhibitions: [], reaction: nil, **opts)
      @app = app
      @killer = killer
      @interval = interval

      @inhibitions = inhibitions.dup.freeze

      @reaction = reaction || method(:default_kill)

      @limiter = klass.new(**opts)
      @last_reacted_at = 0.0
      @inhibited = 0
      @delayed_reaction = nil
    end

    def call(env)
      if (path_info = env['PATH_INFO']) && inhibitions.any?{|i| path_info[i] }
        call_with_inhibition(env, path_info) do
          # реакция будет вызвана после реального окончания обработки
          react if limiter.check
        end
      else
        @app.call(env).tap do
          # реакция будет вызвана сейчас (как обычно)
          react if limiter.check
        end
      end
    end

    def call_with_inhibition(env, path_info, &after)
      inihibit(path_info)

      rack_response = nil
      begin
        rack_response = @app.call(env)
      rescue Exception
        # в случае ошибоки во время @app.call возращаем как было
        release
        raise
      end

      # Почему именно each описано в спецификации в разделе The Response
      # https://github.com/rack/rack/blob/main/SPEC.rdoc
      if rack_response[2].respond_to?(:each)
        rack_response[2] = wrap_rack_response_body(rack_response[2], &after)
      else
        release # освобождаем сразу
        after.call
      end

      rack_response
    end

    def wrap_rack_response_body(rack_response_body, &after)
      Enumerator.new do |y|
        rack_response_body.each {|chunk| y << chunk }
        # Почему именно close описано в спецификации в разделе The Response
        # https://github.com/rack/rack/blob/main/SPEC.rdoc
        rack_response_body.close if rack_response_body.respond_to?(:close)

        release # освобождаем после отправки всего тела
        after.call
      end
    end

    def react
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return if now - @last_reacted_at < @interval

      @last_reacted_at = now
      if @inhibited > 0
        @delayed_reaction = -> { reaction.call(limiter, killer) }
      else
        reaction.call(limiter, killer)
      end
    end

    def default_kill(l, k)
      k.kill(l.started_at)
    end

    def inihibit(_path_info)
      @inhibited += 1
    end

    def release
      return unless ((@inhibited -= 1) == 0) && @delayed_reaction

      @delayed_reaction.tap do |cb|
        @delayed_reaction = nil
        cb.call
      end
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

