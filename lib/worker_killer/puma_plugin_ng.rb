require 'delegate'
require 'singleton'

require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'


module WorkerKiller
  class PumaPluginNg

    include Singleton

    class PumaLogWrapper < SimpleDelegator

      def info(msg)
        __getobj__.log(msg)
      end

      def warn(msg)
        __getobj__.log(msg)
      end

    end

    attr_accessor :killer, :puma_server, :kill_queue

    def initialize
      @killer = ::WorkerKiller::Killer::Puma.new(worker_num: nil, puma_plugin: self)
      @worker_num = nil
      @debug = false

      @puma_server = nil

      @force_restart = %w[t 1].include?(ENV.fetch('WORKER_KILLER_PUMA_AGGRESSIVE', 'false').to_s.downcase[0].to_s)
      @kill_queue ||= Set.new
      @last_restarted_at = 0.0
    end

    # Этот метод зовётся при ИНИЦИАЛИЗАЦИИ плагина внути master-процесса, в самомо начале
    # тут можно выполнить конфигурацию чегоднибудь нужного
    def config(dsl)
      if %w[t 1].include?(ENV.fetch('WORKER_KILLER_DEBUG', 'false').to_s.downcase[0].to_s)
        @debug = true
      end

      cb = if dsl.respond_to?(:before_worker_boot)
        :before_worker_boot
      else
        # DEPRECATED
        :on_worker_boot
      end

      puts "SEND:#{cb}"

      dsl.send(cb) do |num|
        @killer.worker_num = num
        @worker_num = num
        @tag = nil
        log "Set worker_num: #{num}"
      end

      dsl.out_of_band do
        do_kill('OOB') unless @force_restart
      end
    end

    # Этот метод зовётся при ИНИЦИАЛИЗАЦИИ плагина внути master-процесса, контролирующего кластер Puma
    # псле форка данные сохранённые тут также доступны (например logger)
    def start(launcher)
      set_logger!(PumaLogWrapper.new(launcher.log_writer))
    end

    def set_logger!(logger)
      @logger = logger
    end

    # Завершать процесс сразу после окончания inhibited метода. Иначе завершение будет происзодть в Out Of Band методе
    def force_restart!(force = true)
      @force_restart = force
    end

    # Этот метод зовётся из Middleware внтури воркера
    def request_restart_server(worker_num)
      return if @worker_num != worker_num

      log("Enqueue worker #{worker_num} for restarting...")
      kill_queue << worker_num
      do_kill('FORCE') if @force_restart
    end

    def do_kill(name)
      return if kill_queue.empty?

      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return if now - @last_restarted_at < 10

      @last_restarted_at = now
      log "Killing workers by #{name}: #{kill_queue}"
      kill_queue.each do |worker_num|
        kill_queue.delete(worker_num)
        Thread.current.puma_server.options[:force_shutdown_after] = nil
        Thread.current.puma_server.begin_restart
      end
    end

    def log(msg)
      if @logger
        @logger.warn("#{tag} #{msg}")
      else
        warn("[#{Process.pid}] #{tag} #{msg}")
      end
    end

    def tag
      @tag ||= "[#{self.class}] #{@worker_num.nil? ? '[M]' : "[W#{@worker_num}]"}"
    end

    def debug(msg)
      return unless @debug

      if @logger
        @logger.warn("#{tag} (DEBUG) #{msg}")
      else
        warn("[#{Process.pid}] #{tag} (DEBUG) #{msg}")
      end
    end

  end
end

